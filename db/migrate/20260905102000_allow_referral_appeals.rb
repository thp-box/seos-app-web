class AllowReferralAppeals < ActiveRecord::Migration[8.1]
  def change
    change_column_null :trust_appeals, :trust_score_snapshot_id, true
    add_reference :trust_appeals, :referral, foreign_key: true
    add_check_constraint :trust_appeals, "(trust_score_snapshot_id IS NOT NULL AND referral_id IS NULL) OR (trust_score_snapshot_id IS NULL AND referral_id IS NOT NULL)", name: "one_trust_appeal_source"
    add_index :trust_appeals, [ :user_id, :referral_id ], unique: true, where: "status IN ('open', 'investigating')", name: "one_open_referral_appeal"
  end
end
