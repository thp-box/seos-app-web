class RemoveReferralAgeSettings < ActiveRecord::Migration[8.1]
  def up
    drop_table :referral_exemptions
    drop_table :referral_settings
  end

  def down
    create_table :referral_settings do |t|
      t.integer :minimum_age_days, null: false, default: 30
      t.timestamps
    end
    add_check_constraint :referral_settings, "id = 1 AND minimum_age_days >= 0", name: "referral_settings_singleton"
    create_table :referral_exemptions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :granted_by, null: false, foreign_key: { to_table: :users }
      t.string :reason, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
  end
end
