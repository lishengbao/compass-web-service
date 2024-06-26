# frozen_string_literal: true

module Mutations
  module Tpc
    class CreateTpcSoftwareSelectionReport < BaseMutation
      include CompassUtils

      field :status, String, null: false

      argument :label, String, required: true, description: 'repo or project label'
      argument :level, String, required: false, description: 'repo or comunity', default_value: 'repo'
      argument :report_type, Integer, required: true, description: 'selection: 0, create_repo: 1, incubation: 2'
      argument :software_report, Input::TpcSoftwareSelectionReportInput, required: true

      CharacterSet = '0123456789abcdefghijklmnopqrstuvwxyz'

      def resolve(label: nil,
                  level: 'repo',
                  report_type: 0,
                  software_report: nil
      )
        label = ShortenedLabel.normalize_label(label)
        current_user = context[:current_user]
        login_required!(current_user)

        subject = Subject.find_by(label: label, level: level)
        raise GraphQL::ExecutionError.new I18n.t('basic.subject_not_exist') if subject.nil?
        tpc_software_selection_report = TpcSoftwareSelectionReport.find_by(subject_id: subject.id, code_url: software_report.code_url)
        raise GraphQL::ExecutionError.new I18n.t('tpc.software_report_already_exist') if tpc_software_selection_report.present?
        raise GraphQL::ExecutionError.new I18n.t('tpc.software_code_url_invalid') unless TpcSoftwareMetricServer.check_url(software_report.code_url)

        ActiveRecord::Base.transaction do
          software_report_data = software_report.as_json
          software_report_data["user_id"] = current_user.id
          software_report_data["subject_id"] = subject.id
          software_report_data["report_type"] = report_type
          software_report_data["short_code"] = "s#{Nanoid.generate(size: 7, alphabet: CharacterSet)}"
          tpc_software_selection_report = TpcSoftwareSelectionReport.create!(software_report_data)

          report_metric = tpc_software_selection_report.tpc_software_report_metrics.create!(
            {
              code_url: tpc_software_selection_report.code_url,
              status: TpcSoftwareReportMetric::Status_Progress,
              status_compass_callback: 0,
              status_tpc_service_callback: 0,
              version: TpcSoftwareReportMetric::Version_Default,
              user_id: current_user.id,
              subject_id: subject.id,

              base_repo_name: 10,
              base_website_url: 10,
              base_code_url: 10,

              compliance_license: nil,
              compliance_dco: nil,
              compliance_package_sig: nil,
              compliance_license_compatibility: nil,

              ecology_dependency_acquisition: nil, #don't do
              ecology_code_maintenance: nil,
              ecology_community_support: nil,
              ecology_adoption_analysis: nil,  #don't do
              ecology_software_quality: nil, #don't do
              ecology_patent_risk: nil, #don't do

              lifecycle_version_normalization: 10,
              lifecycle_version_number: 10,
              lifecycle_version_lifecycle: nil,

              security_binary_artifact: nil,
              security_vulnerability: nil,
              security_vulnerability_response: nil, #don't do
              security_vulnerability_disclosure: TpcSoftwareMetricServer.check_url(software_report.vulnerability_disclosure) ? 10 : 6,
              security_history_vulnerability: nil
            }
          )

          tpc_software_metric_server = TpcSoftwareMetricServer.new({project_url: software_report.code_url})
          # compliance_license, compliance_package_sig, compliance_license_compatibility
          # ecology_dependency_acquisition, ecology_software_quality, ecology_patent_risk
          # security_binary_artifact, security_vulnerability, security_history_vulnerability
          tpc_software_metric_server.analyze_metric_by_tpc_service(tpc_software_selection_report.id, report_metric.id)

          # compliance_dco
          # ecology_code_maintenance, ecology_community_support
          # lifecycle_version_number, lifecycle_version_lifecycle
          # security_vulnerability_response
          tpc_software_metric_server.analyze_metric_by_compass(tpc_software_selection_report.id, report_metric.id)

        end


        { status: true, message: '' }
      rescue => ex
        { status: false, message: ex.message }
      end

    end
  end
end
