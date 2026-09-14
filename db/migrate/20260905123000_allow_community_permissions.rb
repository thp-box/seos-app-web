class AllowCommunityPermissions < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :feature_flags, name: "feature_flags_key_values"
    add_check_constraint :feature_flags, "key IN ('public_map_enabled', 'financial_support_enabled')", name: "feature_flags_key_values"
  end
  def down
    remove_check_constraint :feature_flags, name: "feature_flags_key_values"
    add_check_constraint :feature_flags, "key = 'public_map_enabled'", name: "feature_flags_key_values"
  end
end
