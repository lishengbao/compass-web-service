# frozen_string_literal: true

class TpcSoftwareMetricServer

  include Common
  include CompassUtils

  DEFAULT_HOST = ENV.fetch('DEFAULT_HOST')

  TPC_SERVICE_API_ENDPOINT = ENV.fetch('TPC_SERVICE_API_ENDPOINT')
  TPC_SERVICE_API_USERNAME = ENV.fetch('TPC_SERVICE_API_USERNAME')
  TPC_SERVICE_API_PASSWORD = ENV.fetch('TPC_SERVICE_API_PASSWORD')
  TPC_SERVICE_CALLBACK_URL = "#{DEFAULT_HOST}/api/tpc_software_callback"

  def initialize(opts = {})
    @project_url = opts[:project_url]
  end

  def analyze_metric_by_compass(report_id, report_metric_id)
    result = AnalyzeServer.new(
      {
        repo_url: @project_url,
        callback: {
          hook_url: TPC_SERVICE_CALLBACK_URL,
          params: {
            callback_type: "tpc_software_callback",
            task_metadata: {
              report_id: report_id,
              report_metric_id: report_metric_id
            }
          }
        }
      }
    ).simple_execute
    Rails.logger.info("analyze metric by compass info: #{result}")
    raise GraphQL::ExecutionError.new result[:message] unless result[:status]
  end

  def analyze_metric_by_tpc_service(report_id, report_metric_id)
    token = tpc_service_token
    commands = ["osv-scanner", "scancode", "binary-checker", "signature-checker", "sonar-scanner", "dependency-checker"]
    payload = {
      commands: commands,
      project_url: "#{@project_url}.git",
      callback_url: TPC_SERVICE_CALLBACK_URL,
      task_metadata: {
        report_id: report_id,
        report_metric_id: report_metric_id
      }
    }
    result = base_post_request("opencheck", payload, token: token)
    Rails.logger.info("analyze metric by tpc service info: #{result}")
    raise GraphQL::ExecutionError.new result[:message] unless result[:status]
  end

  def self.create_issue_workflow(payload)
    issue_title = payload.dig('issue', 'title')
    issue_body = payload.dig('issue', 'body')
    issue_html_url = payload.dig('issue', 'html_url')
    user_html_url = payload.dig('issue', 'user', 'html_url')
    user_name = payload.dig('issue', 'user', 'name')

    Rails.logger.info("create_issue_workflow info: issue_html_url: #{issue_html_url}")


    if issue_title.include?("【孵化选型申请】")
      # save issue url
      issue_body_taskId_matched = issue_body.match(/taskId=(.*?)&projectId=/)
      if issue_body_taskId_matched
        task_id = issue_body_taskId_matched[1].to_i
        selection = TpcSoftwareSelection.find_by(id: task_id)
        if selection.present?
          selection.update!(issue_url: issue_html_url)
        end
      end

      # send email
      issue_body_matched = issue_body.match(/projectId=([^&]+)/)
      if issue_body_matched
        short_code = issue_body_matched[1]
        short_code_list = short_code.split("..").map(&:strip)
        mail_list = TpcSoftwareSig.get_eamil_list_by_short_code(short_code_list)
        if mail_list.length > 0
          title = "TPC孵化选型申请"
          body = "用户正在申请项目进入 OpenHarmony TPC，具体如下："
          state_list = ["【待TPC SIG评审】", "【TPC：待补充信息】", "【TPC SIG评审中】", "【待架构SIG评审】", "【架构：待补充信息】", "【评审通过】"]
          issue_title = issue_title.gsub(Regexp.union(state_list), '')
          mail_list.each do |mail|
            UserMailer.with(
              type: 0,
              title: title,
              body: body,
              user_name: user_name,
              user_html_url: user_html_url,
              issue_title: issue_title,
              issue_html_url: issue_html_url,
              email: mail
            ).email_tpc_software_application.deliver_later
          end
        end

      end
    end
  end

  def self.create_issue_comment_workflow(payload)
    issue_title = payload.dig('issue', 'title')
    issue_body = payload.dig('issue', 'body')
    issue_html_url = payload.dig('issue', 'html_url')
    user_html_url = payload.dig('issue', 'user', 'html_url')
    user_name = payload.dig('issue', 'user', 'name')
    comment = payload.dig('note')

    Rails.logger.info("create_issue_comment_workflow info: issue_html_url: #{issue_html_url}")

    if issue_title.include?("【孵化选型申请】") && (comment.start_with?("TPC垂域Committer") || comment.start_with?("TPC SIG Leader"))
      # send email
      issue_body_matched = issue_body.match(/projectId=([^&]+)/)
      if issue_body_matched
        short_code = issue_body_matched[1]
        short_code_list = short_code.split("..").map(&:strip)
        mail_list = TpcSoftwareSig.get_eamil_list_by_short_code(short_code_list)
        if mail_list.length > 0
          title = "TPC孵化选型评审"
          body = "用户正在申请项目进入 OpenHarmony TPC，#{comment}，具体如下："
          state_list = ["【待TPC SIG评审】", "【TPC：待补充信息】", "【TPC SIG评审中】", "【待架构SIG评审】", "【架构：待补充信息】", "【评审通过】"]
          issue_title = issue_title.gsub(Regexp.union(state_list), '')
          mail_list.each do |mail|
            UserMailer.with(
              type: 1,
              title: title,
              body: body,
              user_name: user_name,
              user_html_url: user_html_url,
              issue_title: issue_title,
              issue_html_url: issue_html_url,
              email: mail
            ).email_tpc_software_application.deliver_later
          end
        end

      end
    end
  end

  def tpc_software_callback(command_list, scan_results, task_metadata)
    code_count = nil
    license = nil

    # commands = ["osv-scanner", "scancode", "binary-checker", "signature-checker", "sonar-scanner", "dependency-checker", "compass"]
    metric_hash = Hash.new
    metric_raw_hash = Hash.new
    command_list.each do |command|
      case command
      when "osv-scanner"
        metric_hash.merge!(TpcSoftwareReportMetric.get_security_vulnerability(scan_results.dig(command) || {}))
      when "scancode"
        metric_hash.merge!(TpcSoftwareReportMetric.get_compliance_license(@project_url, scan_results.dig(command) || {}))
        metric_hash.merge!(TpcSoftwareReportMetric.get_compliance_license_compatibility(scan_results.dig(command) || {}))
        license = TpcSoftwareReportMetric.get_license(@project_url, scan_results.dig(command) || {})
      when "binary-checker"
        metric_hash.merge!(TpcSoftwareReportMetric.get_security_binary_artifact(scan_results.dig(command) || {}))
      when "signature-checker"
        metric_hash.merge!(TpcSoftwareReportMetric.get_compliance_package_sig(scan_results.dig(command) || {}))
      when "sonar-scanner"
        metric_hash.merge!(TpcSoftwareReportMetric.get_ecology_software_quality(scan_results.dig(command) || {}))
        code_count = TpcSoftwareReportMetric.get_code_count(scan_results.dig(command) || {})
      when "dependency-checker"
        metric_hash.merge!(TpcSoftwareReportMetric.get_ecology_dependency_acquisition(scan_results.dig(command) || {}))
      when "compass"
        metric_hash.merge!(TpcSoftwareReportMetric.get_compliance_dco(@project_url))
        metric_hash.merge!(TpcSoftwareReportMetric.get_ecology_code_maintenance(@project_url))
        metric_hash.merge!(TpcSoftwareReportMetric.get_ecology_community_support(@project_url))
        metric_hash.merge!(TpcSoftwareReportMetric.get_security_history_vulnerability(@project_url))
        metric_hash.merge!(TpcSoftwareReportMetric.get_lifecycle_version_lifecycle(@project_url))
      else
        raise GraphQL::ExecutionError.new I18n.t('tpc.callback_command_not_exist', command: command)
      end
    end
    report_metric_id = task_metadata["report_metric_id"]
    tpc_software_report_metric = TpcSoftwareReportMetric.find_by(id: report_metric_id)
    raise GraphQL::ExecutionError.new I18n.t('basic.subject_not_exist') if tpc_software_report_metric.nil?

    report_metric_data = metric_hash.select { |key, _| !key.end_with?("_raw") }
    report_metric_raw_data = metric_hash.select { |key, _| key.end_with?("_raw") }
    if command_list.include?("compass")
      report_metric_data["status_compass_callback"] = 1
      if tpc_software_report_metric.status_tpc_service_callback == 1
        report_metric_data["status"] = TpcSoftwareReportMetric::Status_Success
      end
    else
      report_metric_data["status_tpc_service_callback"] = 1
      if tpc_software_report_metric.status_compass_callback == 1
        report_metric_data["status"] = TpcSoftwareReportMetric::Status_Success
      end
    end
    ActiveRecord::Base.transaction do
      tpc_software_report_metric.update!(report_metric_data)

      tpc_software_selection_report = TpcSoftwareSelectionReport.find_by(id: task_metadata["report_id"])
      update_data = {}
      update_data[:code_count] = code_count unless code_count.nil?
      update_data[:license] = license unless license.nil?
      if update_data.present?
        tpc_software_selection_report.update!(update_data)
      end


      if report_metric_raw_data.length > 0
        metric_raw = TpcSoftwareReportMetricRaw.find_or_initialize_by(tpc_software_report_metric_id: tpc_software_report_metric.id)
        report_metric_raw_data[:tpc_software_report_metric_id] = tpc_software_report_metric.id
        report_metric_raw_data[:code_url] = tpc_software_report_metric.code_url
        report_metric_raw_data[:subject_id] = tpc_software_report_metric.subject_id
        metric_raw.update!(report_metric_raw_data)
      end
    end
  end

  def tpc_service_token
    payload = {
      username: TPC_SERVICE_API_USERNAME,
      password: TPC_SERVICE_API_PASSWORD
    }
    result = base_post_request("auth", payload)
    raise GraphQL::ExecutionError.new result[:message] unless result[:status]
    result[:body]["access_token"]
  end

  def base_post_request(request_path, payload, token: nil)
    header = { 'Content-Type' => 'application/json' }
    if token
      header["Authorization"] = "JWT #{token}"
    end
    resp = RestClient::Request.new(
      method: :post,
      url: "#{TPC_SERVICE_API_ENDPOINT}/#{request_path}",
      payload: payload.to_json,
      headers: header,
      proxy: PROXY
    ).execute
    resp_hash = JSON.parse(resp.body)
    if resp.body.include?("error")
      { status: false, message: I18n.t('tpc.software_report_trigger_failed', reason: resp_hash['description']) }
    else
      { status: true, body: resp_hash }
    end
  rescue => ex
    { status: false, message: I18n.t('tpc.software_report_trigger_failed', reason: ex.message) }
  end

end