# frozen_string_literal: true
module Types
  module Metric
    class ModelType < Types::BaseObject
      field :ident, String, null: false
      field :type, String, description: 'metric scores for repositories type, only for community (software-artifact/governance)'
      field :label, String, description: 'metric model object identification'
      field :level, String, description: 'metric model object level'
      field :main_score, Float, description: 'metric model main score'
      field :transformed_score, Float, description: 'metric model transformed score'
      field :grimoire_creation_date, GraphQL::Types::ISO8601DateTime, description: 'metric model create or update time'
    end
  end
end
