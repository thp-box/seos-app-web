class ProtectPointDecisionInputs < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TRIGGER point_adjustment_inputs_immutable BEFORE UPDATE ON point_adjustments
      WHEN NEW.user_id != OLD.user_id OR NEW.proposed_by_id != OLD.proposed_by_id OR NEW.amount != OLD.amount
        OR NEW.balance_before != OLD.balance_before OR NEW.reason != OLD.reason OR NEW.expires_at != OLD.expires_at
        OR OLD.point_operation_id IS NOT NULL
      BEGIN SELECT RAISE(ABORT, 'immutable adjustment preview'); END
    SQL
    execute <<~SQL
      CREATE TRIGGER point_claim_inputs_immutable BEFORE UPDATE ON point_reward_claims
      WHEN NEW.user_id != OLD.user_id OR NEW.point_rule_version_id != OLD.point_rule_version_id OR NEW.kind != OLD.kind
        OR NEW.period_key != OLD.period_key OR NEW.evidence != OLD.evidence OR NEW.amount != OLD.amount OR NEW.level != OLD.level
        OR OLD.status != 'pending'
      BEGIN SELECT RAISE(ABORT, 'immutable reward evidence'); END
    SQL
  end

  def down
    execute "DROP TRIGGER point_adjustment_inputs_immutable"
    execute "DROP TRIGGER point_claim_inputs_immutable"
  end
end
