# frozen_string_literal: true

module Types
  module Queries
    module Tpc
      class TpcSoftwareSelectionReportQuery < BaseQuery
        include Pagy::Backend

        type Types::Tpc::TpcSoftwareSelectionReportType, null: true
        description 'Get tpc software selection report apply page'
        argument :short_code, String, required: true


        def resolve(short_code: nil)
          current_user = context[:current_user]
          login_required!(current_user)

          report = TpcSoftwareSelectionReport.find_by(short_code: short_code)
          if report
            report_hash = report.attributes
            clarification_committer_permission = TpcSoftwareReportMetricClarificationState.check_committer_permission?(report.tpc_software_sig_id, current_user)
            clarification_sig_lead_permission = TpcSoftwareReportMetricClarificationState.check_sig_lead_permission?(current_user)
            report_hash['clarification_committer_permission'] = clarification_committer_permission ? 1 : 0
            report_hash['clarification_sig_lead_permission'] = clarification_sig_lead_permission ? 1 : 0
            report = OpenStruct.new(report_hash)
          end
          report
        end
      end
    end
  end
end
