# == Schema Information
#
# Table name: tpc_software_selection_reports
#
#  id                              :bigint           not null, primary key
#  report_type                     :integer          not null
#  name                            :string(255)      not null
#  tpc_software_sig_id             :integer          not null
#  release                         :string(255)
#  release_time                    :datetime
#  manufacturer                    :string(255)      not null
#  website_url                     :string(255)      not null
#  code_url                        :string(255)      not null
#  programming_language            :string(255)      not null
#  code_count                      :integer
#  license                         :string(255)
#  vulnerability_disclosure        :string(255)
#  vulnerability_response          :string(255)
#  short_code                      :string(255)      not null
#  subject_id                      :integer          not null
#  user_id                         :integer          not null
#  created_at                      :datetime         not null
#  updated_at                      :datetime         not null
#  adaptation_method               :string(255)
#  oh_commit_sha                   :string(255)
#  report_category                 :integer
#  upstream_collaboration_strategy :integer
#  upstream_communication_link     :string(255)
#
# Indexes
#
#  index_tpc_software_selection_reports_on_short_code  (short_code) UNIQUE
#
class TpcSoftwareSelectionReport < ApplicationRecord
  include ActiveStorageSupport::SupportForBase64
  alias_attribute :architecture_diagrams, :attachments

  belongs_to :tpc_software_sig
  belongs_to :subject
  belongs_to :user
  has_many :tpc_software_report_metrics, as: :tpc_software_report, dependent: :destroy
  has_many :tpc_software_selections, foreign_key: 'target_software_report_id'

  has_many_base64_attached :attachments

  Report_Type_Incubation = 0
  Report_Type_Sandbox = 1

  CharacterSet = '0123456789abcdefghijklmnopqrstuvwxyz'

  def self.generate_short_code
    loop do
      short_code = "s#{Nanoid.generate(size: 7, alphabet: CharacterSet)}"
      break short_code unless TpcSoftwareSelectionReport.exists?(short_code: short_code)
    end
  end

end
