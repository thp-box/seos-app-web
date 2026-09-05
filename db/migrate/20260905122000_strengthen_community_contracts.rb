class StrengthenCommunityContracts < ActiveRecord::Migration[8.1]
  def up
    add_column :financial_contributions, :refund_requested_at, :datetime
    execute "CREATE TRIGGER financial_inputs_immutable BEFORE UPDATE ON financial_contributions WHEN NEW.user_id != OLD.user_id OR NEW.request_key != OLD.request_key OR NEW.amount_cents != OLD.amount_cents OR NEW.currency != OLD.currency BEGIN SELECT RAISE(ABORT, 'immutable financial inputs'); END"
    execute "CREATE TRIGGER achievement_inputs_immutable BEFORE UPDATE ON user_achievements WHEN OLD.status = 'approved' OR NEW.user_id != OLD.user_id OR NEW.achievement_id != OLD.achievement_id OR NEW.point_rule_version_id != OLD.point_rule_version_id OR NEW.points != OLD.points OR NEW.period_key != OLD.period_key OR NEW.evidence != OLD.evidence BEGIN SELECT RAISE(ABORT, 'immutable achievement inputs'); END"
    execute "CREATE TRIGGER chain_services_no_delete BEFORE DELETE ON chain_services BEGIN SELECT RAISE(ABORT, 'immutable chain history'); END"
  end
  def down
    execute "DROP TRIGGER financial_inputs_immutable"
    execute "DROP TRIGGER achievement_inputs_immutable"
    execute "DROP TRIGGER chain_services_no_delete"
    remove_column :financial_contributions, :refund_requested_at
  end
end
