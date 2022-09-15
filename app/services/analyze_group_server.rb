# frozen_string_literal: true

class AnalyzeGroupServer
  SUPPORT_DOMAINS = ['gitee.com', 'github.com']
  CELERY_SERVER = ENV.fetch('CELERY_SERVER') { 'http://localhost:8000' }
  PROJECT = 'insight'
  WORKFLOW = 'ETL_V1_GROUP'

  class TaskExists < StandardError; end
  class ValidateError < StandardError; end

  def initialize(opts = {})
    @yaml_url = opts[:yaml_url]
    @raw = opts[:raw] || true
    @enrich = opts[:enrich] || true
    @activity = opts[:activity] || true
    @community = opts[:community] || true
    @codequality = opts[:codequality] || true
    @callback = opts[:callback]
    @level = 'project'

    if @yaml_url.present?
      uri = Addressable::URI.parse(@yaml_url)
      @yaml_url = "https://#{uri&.normalized_host}#{uri&.path}"
      @domain = uri&.normalized_host
    end
  end

  def repo_task
    @repo_task ||= RepoTask.find_by(repo_url: @yaml_url)
  end

  def check_task_status
    if repo_task.present?
      update_task_status
      repo_task.status
    else
      RepoTask::UnSubmit
    end
  end

  def execute(only_validate: false)
    validate!

    status = check_task_status

    if RepoTask::Processing.include?(status)
      raise TaskExists.new('Task already sumbitted!')
    end

    if only_validate
      { status: true, message: 'validate pass' }
    else
      result = submit_task_status
      { status: result[:status], message: result[:message] }
    end
  rescue TaskExists => ex
    { status: :progress, message: ex.message }
  rescue ValidateError => ex
    { status: :error, message: ex.message }
  end

  private

  def validate!
    raise ValidateError.new('`yaml_url` is required') unless @yaml_url.present?

    unless SUPPORT_DOMAINS.include?(@domain)
      raise ValidateError.new("No support data source from: #{@yaml_url}")
    end

    tasks = [@raw, @enrich, @activity, @community, @codequality]
    raise ValidateError.new('No tasks enabled') unless tasks.any?

    # yaml = YAML.load(Faraday.get(@yaml_url).body)
    # org_name = yaml['organization_name']
    # project_types = yaml['project_types']
    # existed_metrics =
    #   project_types.flat_map do |type, _|
    #   [ActivityMetric, CommunityMetric, CodequalityMetric].map do |metric|
    #     metric.exist_one?('label', "#{org_name}-#{type}")
    #   end
    # end

    # if existed_metrics.any?
    #   raise ValidateError.new('organization name already existed')
    # end
  end

  def payload
    {
      project: PROJECT,
      name: WORKFLOW,
      payload: {
        deubg: false,
        enrich: @enrich,
        identities_load: false,
        identities_merge: false,
        metrics_activity: @activity,
        metrics_codequality: @codequality,
        metrics_community: @community,
        panels: false,
        project_template_yaml: @yaml_url,
        raw: @raw,
        level: @level,
        callback: @callback
      }
    }
  end

  def submit_task_status
    repo_task = RepoTask.find_by(repo_url: @yaml_url)

    response =
      Faraday.post(
        "#{CELERY_SERVER}/api/workflows",
        payload.to_json,
        { 'Content-Type' => 'application/json' }
      )
    task_resp = JSON.parse(response.body)

    if repo_task.present?
      repo_task.update(status: task_resp['status'], task_id: task_resp['id'])
    else
      RepoTask.create(
        task_id: task_resp['id'],
        repo_url: @yaml_url,
        status: task_resp['status'],
        payload: payload.to_json
      )
    end
    { status: task_resp['status'], message: 'Task is pending' }
  rescue => ex
    logger.error("Failed to sumbit task #{@yaml_url} status, #{ex.message}")
    { status: RepoTask::UnSubmit, message: 'Failed to sumbit task, please retry' }
  end

  def update_task_status
    if repo_task.task_id
      response =
        Faraday.get("#{CELERY_SERVER}/api/workflows/#{repo_task.task_id}")
      task_resp = JSON.parse(response.body)
      repo_task.update(status: task_resp['status'])
    end
  rescue => ex
    logger.error("Failed to update task #{repo_task.task_id} status, #{ex.message}")
  end
end
