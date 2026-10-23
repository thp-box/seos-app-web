class RemoveLegacyPartnershipConstraints < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :feature_flags, name: "feature_flags_key_values"
    add_check_constraint :feature_flags, "key IN ('public_map_enabled','voyage_enabled')", name: "feature_flags_key_values"
    remove_check_constraint :organizations, name: "organizations_request_kind"
    add_check_constraint :organizations, "request_kind IS NULL OR request_kind = 'community_mission'", name: "organizations_request_kind"
  end

  def down
    remove_check_constraint :organizations, name: "organizations_request_kind"
    add_check_constraint :organizations, "request_kind IS NULL OR request_kind IN ('partnership', 'community_mission')", name: "organizations_request_kind"
    remove_check_constraint :feature_flags, name: "feature_flags_key_values"
    add_check_constraint :feature_flags, "key IN ('public_map_enabled','voyage_enabled','partnerships_enabled')", name: "feature_flags_key_values"
  end
end
