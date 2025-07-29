# frozen_string_literal: true

class GithubGitEnrich < GithubBase

  include BaseEnrich
  include CommitEnrich

  def self.index_name
    'github-git_enriched'
  end
  
  def self.platform_type
    'github'
  end

  def self.mapping
    {"properties"=>
     {"contribution"=>{"type"=>"long"},
      "contribution_type_list"=>
      {"properties"=>
       {"contribution"=>{"type"=>"long"},
        "contribution_type"=>
        {"type"=>"text",
         "fields"=>{"keyword"=>{"type"=>"keyword", "ignore_above"=>256}}}}},
      "contribution_without_observe"=>{"type"=>"long"},
      "contributor"=>
      {"type"=>"text",
       "fields"=>{"keyword"=>{"type"=>"keyword", "ignore_above"=>256}}},
      "ecological_type"=>
      {"type"=>"text",
       "fields"=>{"keyword"=>{"type"=>"keyword", "ignore_above"=>256}}},
      "grimoire_creation_date"=>{"type"=>"date"},
      "is_bot"=>{"type"=>"boolean"},
      "metadata__enriched_on"=>{"type"=>"date"},
      "organization"=>
      {"type"=>"text",
       "fields"=>{"keyword"=>{"type"=>"keyword", "ignore_above"=>256}}},
      "repo_name"=>
      {"type"=>"text",
       "fields"=>{"keyword"=>{"type"=>"keyword", "ignore_above"=>256}}},
      "uuid"=>
      {"type"=>"text",
       "fields"=>{"keyword"=>{"type"=>"keyword", "ignore_above"=>256}}}}}
  end
end
