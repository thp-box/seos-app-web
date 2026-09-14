class CreateLaunchTools < ActiveRecord::Migration[8.1]
  def change
    create_table :studio_versions do |t|
      t.string :name, null: false
      t.string :status, null: false, default: "draft"
      t.json :settings, null: false, default: {}
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :validated_digest
      t.datetime :published_at
      t.timestamps
    end
    create_table :bulk_operations do |t|
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :approved_by, foreign_key: { to_table: :users }
      t.json :targets, null: false, default: {}
      t.text :reason, null: false
      t.datetime :expires_at, null: false
      t.datetime :executed_at
      t.timestamps
    end
    create_table :login_blocks do |t|
      t.string :email_digest, null: false
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.text :reason, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :login_blocks, :email_digest
    create_table :google_identities do |t|
      t.references :user, null: false, foreign_key: true
      t.string :uid, null: false
      t.timestamps
    end
    add_index :google_identities, :uid, unique: true
    add_index :google_identities, :user_id, unique: true, name: "one_google_identity_per_user"
    reversible do |direction|
      direction.up do
        %w[studio_versions retention_policy_versions].each do |table|
          execute "CREATE TRIGGER #{table}_no_update BEFORE UPDATE ON #{table} WHEN OLD.status = 'published' BEGIN SELECT RAISE(ABORT, 'published version immutable'); END"
          execute "CREATE TRIGGER #{table}_no_delete BEFORE DELETE ON #{table} WHEN OLD.status = 'published' BEGIN SELECT RAISE(ABORT, 'published version immutable'); END"
        end
      end
    end
  end
end
