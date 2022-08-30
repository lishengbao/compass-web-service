# frozen_string_literal: true

module Types
  class ActivityMetricType < Types::BaseObject
    field :activity_score, Float, description: 'score of activity metric model'
    field :closed_issues_count, Float, description: 'number of issues closed in the past 90 days'
    field :code_review_count, Float, description: 'mean of comments per PR over the past 90 days'
    field :comment_frequency, Float, description: 'mean of comments per issue over the past 90 days'
    field :commit_frequency, Float, description: 'mean of submissions per week over the past 90 days'
    field :contributor_count, Float, description: 'number of active D1 developers in the past 90 days'
    field :created_since, Float, description: 'number of months since the project was created'
    field :updated_issues_count, Float, description: 'number of issue updates in the past 90 days'
    field :updated_since, Float, description: '(average of months from the last code commit to the time of statistics'
    field :grimoire_creation_date, GraphQL::Types::ISO8601DateTime, description: 'metric model creatiton time'
    field :label, String, description: 'metric model object identification'
    field :level, String, description: 'metric model object level'
  end
end