class CreateTrustAndReferrals < ActiveRecord::Migration[8.1]
  def change
    create_table :referral_exemptions do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :granted_by, null: false, foreign_key: { to_table: :users }
      t.text :reason, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    create_table :referral_codes do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }
      t.string :code_digest, null: false, index: { unique: true }
      t.datetime :expires_at, null: false
      t.datetime :claimed_at
      t.timestamps
    end
    create_table :referrals do |t|
      t.references :referral_code, null: false, foreign_key: true, index: { unique: true }
      t.references :referrer, null: false, foreign_key: { to_table: :users }
      t.references :referred_user, null: false, foreign_key: { to_table: :users }
      t.integer :position, null: false
      t.boolean :primary_referrer, null: false, default: false
      t.string :status, null: false, default: "provisional"
      t.datetime :claimed_at, null: false
      t.datetime :objection_deadline_at, null: false
      t.datetime :confirmed_at
      t.datetime :qualified_at
      t.datetime :invalidated_at
      t.text :invalidation_reason
      t.timestamps
    end
    add_index :referrals, [ :referrer_id, :referred_user_id ], unique: true
    add_index :referrals, [ :referred_user_id, :position ], unique: true
    add_index :referrals, :referred_user_id, unique: true, where: "primary_referrer = 1", name: "one_primary_referrer"
    add_check_constraint :referrals, "position BETWEEN 1 AND 10", name: "referral_position_range"
    add_check_constraint :referrals, "referrer_id != referred_user_id", name: "no_self_referral"
    add_check_constraint :referrals, "status IN ('provisional', 'confirmed', 'objected', 'invalidated')", name: "referral_status"
    create_table :trust_algorithm_versions do |t|
      t.string :version, null: false, index: { unique: true }
      t.string :status, null: false, default: "draft"
      t.json :configuration, null: false, default: {}
      t.text :explanation, null: false
      t.json :simulation, null: false, default: {}
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :activated_at
      t.timestamps
    end
    add_index :trust_algorithm_versions, :status, unique: true, where: "status = 'active'", name: "one_active_trust_algorithm"
    create_table :trust_events do |t|
      t.references :subject, null: false, foreign_key: { to_table: :users }
      t.references :actor, foreign_key: { to_table: :users }
      t.references :service_request, foreign_key: true
      t.references :category, foreign_key: true
      t.references :source, polymorphic: true, null: false
      t.string :source_key, null: false, index: { unique: true }
      t.string :dimension, null: false
      t.string :event_kind, null: false
      t.float :normalized_value, null: false
      t.datetime :occurred_at, null: false
      t.datetime :created_at, null: false
    end
    add_check_constraint :trust_events, "normalized_value >= 0 AND normalized_value <= 1", name: "trust_value_bounds"
    create_table :trust_event_corrections do |t|
      t.references :trust_event, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.boolean :excluded, null: false
      t.text :reason, null: false
      t.datetime :created_at, null: false
    end
    create_table :trust_score_snapshots do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trust_algorithm_version, null: false, foreign_key: true
      t.string :fingerprint, null: false
      t.json :result, null: false, default: {}
      t.json :contributions, null: false, default: []
      t.datetime :calculated_at, null: false
      t.datetime :created_at, null: false
    end
    add_index :trust_score_snapshots, [ :user_id, :trust_algorithm_version_id, :fingerprint ], unique: true, name: "unique_trust_calculation"
    create_table :trust_profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :trust_score_snapshot, null: false, foreign_key: true
      t.timestamps
    end
    create_table :trust_appeals do |t|
      t.references :user, null: false, foreign_key: true
      t.references :trust_score_snapshot, null: false, foreign_key: true
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.text :statement, null: false
      t.string :status, null: false, default: "open"
      t.text :decision
      t.datetime :decided_at
      t.datetime :response_due_at, null: false
      t.timestamps
    end
    add_index :trust_appeals, [ :user_id, :trust_score_snapshot_id ], unique: true, where: "status IN ('open', 'investigating')", name: "one_open_trust_appeal"
    create_table :trust_risk_assessments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.string :signal, null: false
      t.integer :evidence_count, null: false
      t.string :status, null: false, default: "open"
      t.text :decision
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :trust_risk_assessments, [ :user_id, :signal ], unique: true, where: "status = 'open'", name: "one_open_trust_signal"
    add_column :review_ratings, :dimension_snapshot, :string
    reversible do |dir|
      dir.up do
        execute "UPDATE review_ratings SET dimension_snapshot = (SELECT key FROM review_criteria WHERE review_criteria.id = review_ratings.review_criterion_id)"
        %w[trust_events trust_event_corrections trust_score_snapshots].each do |table|
          %w[UPDATE DELETE].each do |operation|
            execute "CREATE TRIGGER #{table}_no_#{operation.downcase} BEFORE #{operation} ON #{table} BEGIN SELECT RAISE(ABORT, 'immutable trust history'); END"
          end
        end
      end
      dir.down do
        %w[trust_events trust_event_corrections trust_score_snapshots].each do |table|
          %w[update delete].each { |operation| execute "DROP TRIGGER IF EXISTS #{table}_no_#{operation}" }
        end
      end
    end
  end
end
