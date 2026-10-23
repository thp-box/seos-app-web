class RemoveFinancialSupport < ActiveRecord::Migration[8.1]
  def up
    remove_check_constraint :feature_flags, name: "feature_flags_key_values"
    execute "DELETE FROM feature_flags WHERE key = 'financial_support_enabled'"
    execute "UPDATE notifications SET category = 'general' WHERE category = 'support'"
    execute "DELETE FROM provider_erasure_tasks WHERE provider = 'stripe'"
    add_check_constraint :feature_flags, "key IN ('public_map_enabled','voyage_enabled','partnerships_enabled')", name: "feature_flags_key_values"
    drop_table :payment_events
    drop_table :financial_contributions
  end

  def down
    create_table :financial_contributions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :request_key, null: false
      t.integer :amount_cents, null: false
      t.string :currency, null: false, default: "eur"
      t.string :status, null: false, default: "pending"
      t.string :stripe_session_id, index: { unique: true }
      t.string :payment_intent_id, index: { unique: true }
      t.string :stripe_refund_id
      t.integer :refunded_cents, null: false, default: 0
      t.timestamps
    end
    add_index :financial_contributions, [ :user_id, :request_key ], unique: true
    create_table :payment_events do |t|
      t.string :stripe_event_id, null: false, index: { unique: true }
      t.references :financial_contribution, foreign_key: true
      t.string :event_type, null: false
      t.json :refund_data, null: false, default: {}
      t.datetime :created_at, null: false
    end
    remove_check_constraint :feature_flags, name: "feature_flags_key_values"
    add_check_constraint :feature_flags, "key IN ('public_map_enabled','financial_support_enabled','voyage_enabled','partnerships_enabled')", name: "feature_flags_key_values"
  end
end
