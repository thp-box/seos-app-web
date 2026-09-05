class CreateCommunityPolicyVersions < ActiveRecord::Migration[8.1]
  def up
    create_table :community_policy_versions do |t|
      t.integer :urgent_days, null: false, default: 7
      t.integer :top_max_days, null: false, default: 30
      t.references :created_by, foreign_key: { to_table: :users }
      t.datetime :created_at, null: false
    end
    add_check_constraint :community_policy_versions, "urgent_days BETWEEN 1 AND 30 AND top_max_days BETWEEN 1 AND 90", name: "community_policy_bounds"
    %w[UPDATE DELETE].each { |action| execute "CREATE TRIGGER community_policy_no_#{action.downcase} BEFORE #{action} ON community_policy_versions BEGIN SELECT RAISE(ABORT, 'immutable community policy'); END" }
  end
  def down
    drop_table :community_policy_versions
  end
end
