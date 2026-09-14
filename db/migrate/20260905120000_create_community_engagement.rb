class CreateCommunityEngagement < ActiveRecord::Migration[8.1]
  def change
    create_table :achievements do |t|
      t.string :slug, null: false, index: { unique: true }
      t.string :name, null: false
      t.text :description, null: false
      t.string :event_name, null: false
      t.string :reward_key, null: false
      t.string :recurrence, null: false, default: "once"
      t.integer :target_count, null: false, default: 1
      t.boolean :builtin, null: false, default: false
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    create_table :user_achievements do |t|
      t.references :user, null: false, foreign_key: true
      t.references :achievement, null: false, foreign_key: true
      t.references :point_rule_version, null: false, foreign_key: true
      t.references :point_operation, foreign_key: true
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.string :period_key, null: false
      t.string :status, null: false, default: "submitted"
      t.integer :points, null: false
      t.text :evidence, null: false
      t.text :decision
      t.datetime :reviewed_at
      t.timestamps
    end
    add_index :user_achievements, [ :user_id, :achievement_id, :period_key ], unique: true, name: "unique_achievement_period"
    create_table :top_listing_requests do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.text :reason
      t.datetime :starts_at
      t.datetime :ends_at
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :top_listing_requests, :listing_id, unique: true, where: "status IN ('pending', 'approved')", name: "one_top_listing_request"
    add_column :listings, :urgent_until, :datetime
    create_table :testimonials do |t|
      t.references :user, null: false, foreign_key: true
      t.references :point_reward_claim, foreign_key: true
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.string :kind, null: false
      t.text :quote, null: false
      t.text :transcript
      t.string :status, null: false, default: "submitted"
      t.string :display_name_snapshot, null: false
      t.string :public_location_snapshot
      t.string :consent_version, null: false
      t.datetime :consented_at, null: false
      t.datetime :published_at
      t.datetime :removed_at
      t.text :decision
      t.timestamps
    end
    create_table :chain_rule_versions do |t|
      t.string :name, null: false
      t.string :status, null: false, default: "draft"
      t.string :length_mode, null: false, default: "unlimited"
      t.integer :max_links
      t.string :reward_scope, null: false, default: "provider_only"
      t.integer :rewarded_previous_links, null: false, default: 1
      t.integer :points_per_validation, null: false, default: 10
      t.integer :max_points_per_link, null: false, default: 30
      t.integer :max_points_per_member, null: false, default: 100
      t.json :simulation, null: false, default: {}
      t.datetime :effective_at, null: false
      t.datetime :published_at
      t.references :created_by, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :chain_rule_versions, :effective_at, unique: true, where: "status = 'published'", name: "one_chain_rule_effective_date"
    create_table :help_chains do |t|
      t.references :creator, null: false, foreign_key: { to_table: :users }
      t.references :chain_rule_version, null: false, foreign_key: true
      t.references :point_rule_version, null: false, foreign_key: true
      t.string :slug, null: false, index: { unique: true }
      t.string :name, null: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    create_table :chain_services do |t|
      t.references :help_chain, null: false, foreign_key: true
      t.references :provider, null: false, foreign_key: { to_table: :users }
      t.references :beneficiary, foreign_key: { to_table: :users }
      t.integer :position, null: false
      t.text :description, null: false
      t.string :invitation_token_digest, null: false, index: { unique: true }
      t.datetime :invitation_expires_at, null: false
      t.string :status, null: false, default: "invited"
      t.datetime :confirmed_at
      t.timestamps
    end
    add_index :chain_services, [ :help_chain_id, :position ], unique: true
    add_index :chain_services, :help_chain_id, unique: true, where: "status = 'invited'", name: "one_chain_invitation"
    add_index :chain_services, [ :help_chain_id, :beneficiary_id ], unique: true, where: "status = 'confirmed'", name: "unique_chain_beneficiary"
    add_check_constraint :chain_services, "provider_id IS NOT beneficiary_id", name: "no_self_chain_validation"
    create_table :chain_rewards do |t|
      t.references :chain_service, null: false, foreign_key: true
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.references :chain_rule_version, null: false, foreign_key: true
      t.references :point_operation, foreign_key: true
      t.integer :points, null: false
      t.integer :reward_rank, null: false
      t.datetime :created_at, null: false
    end
    add_index :chain_rewards, [ :chain_service_id, :recipient_id ], unique: true
    add_check_constraint :chain_rewards, "points >= 0", name: "nonnegative_chain_reward"
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
    add_check_constraint :financial_contributions, "amount_cents BETWEEN 100 AND 100000 AND currency = 'eur' AND refunded_cents BETWEEN 0 AND amount_cents", name: "financial_amount_bounds"
    create_table :payment_events do |t|
      t.string :stripe_event_id, null: false, index: { unique: true }
      t.references :financial_contribution, foreign_key: true
      t.string :event_type, null: false
      t.datetime :created_at, null: false
    end
  end
end
