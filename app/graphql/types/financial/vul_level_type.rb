# frozen_string_literal: true

module Types
  module Financial
    class VulLevelType < BaseObject

      field :vul_levels, Integer, null: true
      field :vul_level_details, [VulPackageType], null: true

    end
  end
end
