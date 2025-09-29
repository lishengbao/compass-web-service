# frozen_string_literal: true

module BaseEnrich
  extend ActiveSupport::Concern
  class_methods do

    def base_terms_by_repo_urls(
          repo_urls, begin_date, end_date,
          target: 'tag', filter: :created_at, sort: :created_at, direction: :asc,
          filter_opts: [], sort_opts: []
        )
      base =
        self
          .must(terms: { target => repo_urls })
          .range(filter, gte: begin_date, lt: end_date)

      if filter_opts.present?
        filter_opts.each do |filter_opt|
          base = base.where(filter_opt.type => filter_opt.values)
        end
      end

      if sort_opts.present?
        sort_opts.each do |sort_opt|
          base = base.sort(sort_opt.type => sort_opt.direction)
        end
      else
        base = base.sort(sort => direction)
      end

      base
    end

    def terms_by_repo_urls(
          repo_urls, begin_date, end_date,
          target: 'tag', filter: :created_at, sort: :created_at, direction: :asc,
          per: 1, page: 1, filter_opts: [], sort_opts: []
        )
      base_terms_by_repo_urls(
        repo_urls, begin_date, end_date,
        target: target, filter: filter, sort: sort, direction: direction,
        filter_opts: filter_opts, sort_opts: sort_opts
      )
        .page(page)
        .per(per)
        .execute
        .raw_response
    end

    def count_by_repo_urls(
          repo_urls, begin_date, end_date,
          target: 'tag', filter: :created_at, filter_opts: []
        )
      base =
        self
          .must(terms: { target => repo_urls })
          .range(filter, gte: begin_date, lt: end_date)
      if filter_opts.present?
        filter_opts.each do |filter_opt|
          base = base.where(filter_opt.type => filter_opt.values)
        end
      end
      base.total_entries
    end


    def count_contributor_by_repo_urls(repo_urls, begin_date, end_date, contributor_type: ["code_author"])
      resp = self.must(terms: { 'repo_name.keyword': repo_urls })
                 .must(match_phrase: { is_bot: "false" })
                 .range(:grimoire_creation_date, gte: begin_date, lt: end_date)
                 .must(terms: { 'contribution_type_list.contribution_type.keyword': contributor_type })
                 .aggregate(
                    count: {
                      cardinality: {
                        field: "contributor.keyword"
                      }
                    }
                 )
                 .per(0)
                 .execute
                 .raw_response

      resp.dig('aggregations', 'count', 'value') || 0

    end


    def check_exist(repo_url)
      resp = self.must(terms: { "tag" => repo_url })
                 .page(1)
                 .per(1)
                 .execute
                 .raw_response

      hits = resp&.[]('hits')&.[]('hits') || []
      return hits.size > 0

    end

    ## Export csv callback

    def on_each(args)
      args[:source]
    end

    def on_finish(args)
      blob = ActiveStorage::Attachment.find_by(blob_id: args[:blob_id], name: 'exports')
      if blob
        Rails.cache.write("export-#{args[:uuid]}", { status: ::Subject::COMPLETE, blob_id: args[:blob_id] })
      else
        Rails.cache.write("export-#{args[:uuid]}", { status: ::Subject::UNKNOWN })
      end
    end
  end
end
