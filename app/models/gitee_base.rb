# frozen_string_literal: true

class GiteeBase < IndexBase
  def self.terms_by_repo_urls(repo_urls,
                              begin_date, end_date,
                              target: 'tag',
                              filter: :created_at,
                              sort: :created_at,
                              direction: :asc,
                              per: 1, page: 1)
    self
      .must(terms: { target => repo_urls })
      .page(page)
      .per(per)
      .range(filter, gte: begin_date, lte: end_date)
      .sort(sort => direction)
      .execute
      .raw_response
  end

  def self.count_by_repo_urls(repo_urls,
                              begin_date, end_date,
                              target: 'tag',
                              filter: :created_at)
    self
      .must(terms: { target => repo_urls })
      .range(filter, gte: begin_date, lte: end_date)
      .total_entries
  end
end
