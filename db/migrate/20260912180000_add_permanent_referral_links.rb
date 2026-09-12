class AddPermanentReferralLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :referral_settings do |t|
      t.integer :minimum_age_days, null: false, default: 30
      t.timestamps
    end
    add_check_constraint :referral_settings, "id = 1 AND minimum_age_days >= 0", name: "referral_settings_singleton"
    create_table :referral_links do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }, index: { unique: true }
      t.string :token, null: false
      t.timestamps
    end
    add_index :referral_links, :token, unique: true
    change_column_null :referrals, :referral_code_id, true
    add_reference :referrals, :referral_link, foreign_key: true
    add_index :referrals, :referred_user_id, unique: true, where: "referral_link_id IS NOT NULL", name: "one_invitation_per_member"
    add_reference :users, :pending_referral_link, foreign_key: { to_table: :referral_links }
  end
end
