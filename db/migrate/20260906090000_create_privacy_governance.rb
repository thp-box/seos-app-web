class CreatePrivacyGovernance < ActiveRecord::Migration[8.1]
  def change
    create_table :cookie_consents do |t|
      t.string :visitor_digest, null: false
      t.string :version, null: false
      t.boolean :analytics, null: false, default: false
      t.boolean :external_media, null: false, default: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :cookie_consents, [ :visitor_digest, :created_at ]
    create_table :data_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.text :details, :response
      t.datetime :verified_at, :completed_at, :export_expires_at
      t.datetime :response_due_at, null: false
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.json :preview, null: false, default: {}
      t.timestamps
    end
    add_index :data_requests, [ :user_id, :kind ], unique: true, where: "status IN ('pending','reviewed','executing')", name: "unique_open_data_request"
    create_table :retention_policy_versions do |t|
      t.string :name, null: false
      t.string :status, null: false, default: "draft"
      t.json :rules, null: false, default: {}
      t.datetime :effective_at, :expires_at, :legal_reviewed_at, :published_at
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.json :simulation, null: false, default: {}
      t.timestamps
    end
    create_table :privacy_runs do |t|
      t.references :retention_policy_version, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "preview"
      t.json :targets, null: false, default: {}
      t.datetime :expires_at, null: false
      t.datetime :executed_at
      t.text :reason, null: false
      t.timestamps
    end
    create_table :provider_erasure_tasks do |t|
      t.references :data_request, null: false, foreign_key: true
      t.string :provider, null: false
      t.string :status, null: false, default: "pending"
      t.text :response
      t.datetime :completed_at
      t.timestamps
    end
    add_index :provider_erasure_tasks, [ :data_request_id, :provider ], unique: true
  end
end
