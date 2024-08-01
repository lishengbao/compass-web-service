# frozen_string_literal: true

module Types
  module Queries
    module Tpc
      class TpcSoftwareGraduationQuery < BaseQuery
        include Pagy::Backend

        type Types::Tpc::TpcSoftwareGraduationType, null: true
        description 'Get tpc software graduation'
        argument :graduation_id, Integer, required: true

        def resolve(graduation_id: nil)
          current_user = context[:current_user]
          login_required!(current_user)

          graduation = TpcSoftwareGraduation.find_by(id: graduation_id)
          if graduation
            graduation_hash = graduation.attributes
            graduation_report_list = TpcSoftwareGraduationReport.where("id IN (?)", JSON.parse(graduation.tpc_software_graduation_report_ids))

            committer_permission_list = graduation_report_list.map do |graduation_report|
              TpcSoftwareMember.check_committer_permission?(graduation_report.tpc_software_sig_id, current_user)
            end
            sig_lead_permission = TpcSoftwareMember.check_sig_lead_permission?(current_user)
            graduation_hash['comment_committer_permission'] = committer_permission_list.include?(true) ? 1 : 0
            graduation_hash['comment_sig_lead_permission'] = sig_lead_permission ? 1 : 0
            report = OpenStruct.new(graduation_hash)
          end
          report

        end
      end
    end
  end
end
