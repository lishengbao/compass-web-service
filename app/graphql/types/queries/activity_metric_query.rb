# frozen_string_literal: true

module Types
  module Queries
    class ActivityMetricQuery < BaseQuery
      type [Types::ActivityMetricType], null: false
      description 'Get activity metrics data of compass'
      argument :url, String, required: true, description: 'repo or project url'
      argument :level, String, required: false, description: 'repo or project', default_value: 'repo'
      argument :begin_date, GraphQL::Types::ISO8601DateTime, required: false, description: 'begin date'
      argument :end_date, GraphQL::Types::ISO8601DateTime, required: false, description: 'end date'

      def resolve(url: nil, level: 'repo', begin_date: nil, end_date: nil)
        uri = Addressable::URI.parse(url)
        repo_url = "#{uri&.scheme}://#{uri&.normalized_host}#{uri&.path}"

        begin_date, end_date, interval = extract_date(begin_date, end_date)

        if !interval
          resp =
            ActivityMetric
              .must(match_phrase: { label: repo_url })
              .page(1)
              .per(30)
              .range(:grimoire_creation_date, gte: begin_date, lte: end_date)
              .execute
              .raw_response
          build_metrics_data(resp, Types::ActivityMetricType) do |skeleton, raw|
            OpenStruct.new(skeleton.merge(raw))
          end
        else
          aggs = generate_interval_aggs(Types::ActivityMetricType, :grimoire_creation_date, interval)
          resp =
            ActivityMetric
              .must(match_phrase: { label: repo_url })
              .page(1)
              .per(1)
              .range(:grimoire_creation_date, gte: begin_date, lte: end_date)
              .aggregate(aggs)
              .execute
              .raw_response

          build_metrics_data(resp, Types::ActivityMetricType) do |skeleton, raw|
            data = raw[:data]
            template = raw[:template]
            skeleton.keys.map do |k|
              key = k.to_s.underscore
              skeleton[key] = data&.[](key)&.[]('value') || template[key]
            end
            skeleton['grimoire_creation_date'] = data&.[]('key_as_string')
            OpenStruct.new(skeleton)
          end
        end
      end
    end
  end
end
