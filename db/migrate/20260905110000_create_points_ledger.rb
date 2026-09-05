class CreatePointsLedger < ActiveRecord::Migration[8.1]
  def change
    create_table :point_rule_versions do |t|
      t.string :family, null: false
      t.string :name, null: false
      t.string :status, null: false, default: "draft"
      t.json :configuration, null: false, default: {}
      t.json :simulation, null: false, default: {}
      t.references :created_by, foreign_key: { to_table: :users }
      t.datetime :effective_at, null: false
      t.datetime :published_at
      t.timestamps
    end
    add_index :point_rule_versions, [ :family, :effective_at ], unique: true, where: "status = 'published'", name: "unique_point_rule_effective_date"
    create_table :point_accounts do |t|
      t.references :user, foreign_key: true, index: { unique: true }
      t.string :kind, null: false, default: "user"
      t.bigint :balance, null: false, default: 0
      t.timestamps
    end
    add_index :point_accounts, :kind, unique: true, where: "kind = 'system'", name: "one_point_system_account"
    add_check_constraint :point_accounts, "(kind = 'user' AND user_id IS NOT NULL AND balance >= 0) OR (kind = 'system' AND user_id IS NULL)", name: "point_account_owner_and_balance"
    add_check_constraint :point_accounts, "typeof(balance) = 'integer' AND balance BETWEEN -9000000000000000 AND 9000000000000000", name: "point_balance_integer"
    create_table :point_operations do |t|
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.string :idempotency_key, null: false, index: { unique: true }
      t.references :initiator, foreign_key: { to_table: :users }
      t.references :source, polymorphic: true, null: false
      t.references :point_rule_version, foreign_key: true
      t.references :reversed_operation, foreign_key: { to_table: :point_operations }, index: { unique: true }
      t.text :reason, null: false
      t.datetime :committed_at
      t.datetime :created_at, null: false
    end
    create_table :point_entries do |t|
      t.references :point_operation, null: false, foreign_key: true
      t.references :point_account, null: false, foreign_key: true
      t.bigint :amount, null: false
      t.bigint :balance_after, null: false
      t.datetime :created_at, null: false
    end
    add_index :point_entries, [ :point_operation_id, :point_account_id ], unique: true, name: "one_entry_per_point_account"
    add_check_constraint :point_entries, "typeof(amount) = 'integer' AND amount != 0 AND amount BETWEEN -999999 AND 999999", name: "point_entry_integer"
    create_table :point_adjustments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :proposed_by, null: false, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.integer :amount, null: false
      t.bigint :balance_before, null: false
      t.text :reason, null: false
      t.datetime :expires_at, null: false
      t.references :point_operation, foreign_key: true
      t.timestamps
    end
    create_table :point_reward_claims do |t|
      t.references :user, null: false, foreign_key: true
      t.references :point_rule_version, null: false, foreign_key: true
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.string :kind, null: false
      t.string :period_key, null: false
      t.string :status, null: false, default: "pending"
      t.text :evidence, null: false
      t.text :decision
      t.string :level, null: false, default: "bronze"
      t.integer :amount, null: false
      t.references :point_operation, foreign_key: true
      t.timestamps
    end
    add_index :point_reward_claims, [ :user_id, :kind, :period_key ], unique: true, name: "unique_point_reward_claim"
    create_table :point_cycle_progresses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :point_rule_version, null: false, foreign_key: true
      t.integer :cycle_number, null: false
      t.json :operation_ids, null: false, default: []
      t.references :point_operation, foreign_key: true
      t.timestamps
    end
    add_index :point_cycle_progresses, [ :user_id, :cycle_number ], unique: true
  end
end
