class CreateAccessFoundations < ActiveRecord::Migration[8.1]
  def change
    create_table :login_sessions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :token_digest, null: false
      t.string :user_agent_summary, null: false
      t.datetime :last_seen_at, null: false
      t.datetime :expires_at, null: false
      t.datetime :revoked_at
      t.datetime :reauthenticated_at
      t.timestamps
    end
    add_index :login_sessions, :token_digest, unique: true
    add_index :login_sessions, :expires_at

    create_table :admin_permission_grants do |t|
      t.references :user, null: false, foreign_key: true
      t.string :permission, null: false
      t.references :granted_by, null: false, foreign_key: { to_table: :users }
      t.datetime :granted_at, null: false
      t.datetime :expires_at
      t.references :revoked_by, foreign_key: { to_table: :users }
      t.datetime :revoked_at
      t.string :reason, null: false
      t.timestamps
    end
    add_index :admin_permission_grants, [ :user_id, :permission ], unique: true,
      where: "revoked_at IS NULL", name: "unique_unrevoked_permission"

    create_table :organizations do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.timestamps
    end
    add_index :organizations, :slug, unique: true
    add_check_constraint :organizations, "kind IN ('association', 'company', 'institution', 'collective')", name: "organizations_kind"
    add_check_constraint :organizations, "status IN ('pending', 'verified', 'rejected', 'suspended')", name: "organizations_status"

    create_table :organization_memberships do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false
      t.string :status, null: false, default: "active"
      t.timestamps
    end
    add_index :organization_memberships, [ :organization_id, :user_id ], unique: true
    add_check_constraint :organization_memberships, "role IN ('owner', 'manager', 'editor')", name: "memberships_role"
    add_check_constraint :organization_memberships, "status IN ('active', 'revoked')", name: "memberships_status"

    create_table :audit_logs do |t|
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.references :target, polymorphic: true, null: false
      t.string :action, null: false
      t.string :reason, null: false
      t.json :metadata, null: false, default: {}
      t.datetime :created_at, null: false
    end
    reversible do |direction|
      direction.up do
        execute "CREATE TRIGGER audit_logs_no_update BEFORE UPDATE ON audit_logs BEGIN SELECT RAISE(ABORT, 'audit_logs are append only'); END"
        execute "CREATE TRIGGER audit_logs_no_delete BEFORE DELETE ON audit_logs BEGIN SELECT RAISE(ABORT, 'audit_logs are append only'); END"
      end
      direction.down do
        execute "DROP TRIGGER IF EXISTS audit_logs_no_update"
        execute "DROP TRIGGER IF EXISTS audit_logs_no_delete"
      end
    end
  end
end
