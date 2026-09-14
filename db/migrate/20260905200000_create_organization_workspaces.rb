class CreateOrganizationWorkspaces < ActiveRecord::Migration[8.1]
  def up
    change_table :organizations do |t|
      t.text :description
      t.string :public_location
      t.text :legal_name, :registration_number, :legal_email
      t.datetime :published_at, :verified_at
      t.references :verified_by, foreign_key: { to_table: :users }
      t.integer :lock_version, null: false, default: 0
    end
    create_table :organization_invitations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.references :accepted_by, foreign_key: { to_table: :users }
      t.text :email, null: false
      t.string :role, null: false
      t.string :token_digest, null: false, index: { unique: true }
      t.datetime :expires_at, null: false
      t.datetime :accepted_at, :revoked_at
      t.timestamps
    end
    create_table :volunteer_missions do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :slug, null: false, index: { unique: true }
      t.string :title, null: false
      t.text :description, :private_address, :accommodation, :meals
      t.string :country_code, :region, :public_location, :languages
      t.date :starts_on, :ends_on
      t.integer :minimum_stay_days, null: false, default: 1
      t.integer :help_hours_per_day, null: false, default: 4
      t.integer :days_off_per_week, null: false, default: 2
      t.integer :daily_contribution_cents, null: false, default: 0
      t.integer :volunteer_capacity, null: false, default: 1
      t.string :status, null: false, default: "draft"
      t.datetime :published_at
      t.references :published_by, foreign_key: { to_table: :users }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_check_constraint :volunteer_missions, "daily_contribution_cents BETWEEN 0 AND 1500 AND volunteer_capacity BETWEEN 1 AND 100 AND minimum_stay_days >= 1 AND help_hours_per_day BETWEEN 1 AND 8 AND days_off_per_week BETWEEN 1 AND 6", name: "mission_bounds"
    create_table :mission_applications do |t|
      t.references :volunteer_mission, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :message, null: false
      t.string :status, null: false, default: "pending"
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.datetime :decided_at
      t.timestamps
    end
    add_index :mission_applications, [ :volunteer_mission_id, :user_id ], unique: true
    create_table :mission_messages do |t|
      t.references :mission_application, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.string :delivery_key, null: false
      t.timestamps
    end
    add_index :mission_messages, [ :mission_application_id, :user_id, :delivery_key ], unique: true, name: "unique_mission_message"
    create_table :partnerships do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :slug, null: false, index: { unique: true }
      t.string :kind, null: false, default: "operational"
      t.string :status, null: false, default: "draft"
      t.string :public_title, :cta_label, :cta_url
      t.text :public_description
      t.date :starts_on, :ends_on
      t.integer :position, null: false, default: 0
      t.references :approved_by, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    remove_check_constraint :feature_flags, name: "feature_flags_key_values"
    add_check_constraint :feature_flags, "key IN ('public_map_enabled','financial_support_enabled','voyage_enabled','partnerships_enabled')", name: "feature_flags_key_values"
    %w[UPDATE DELETE].each do |action|
      condition = action == "UPDATE" ? "AND (NEW.status != 'active' OR NEW.role != 'owner' OR NEW.organization_id != OLD.organization_id)" : ""
      execute "CREATE TRIGGER organization_last_owner_#{action.downcase} BEFORE #{action} ON organization_memberships WHEN OLD.role = 'owner' AND OLD.status = 'active' #{condition} AND NOT EXISTS (SELECT 1 FROM organization_memberships WHERE organization_id = OLD.organization_id AND id != OLD.id AND role = 'owner' AND status = 'active') BEGIN SELECT RAISE(ABORT, 'last organization owner'); END"
    end
  end
  def down
    %w[update delete].each { |action| execute "DROP TRIGGER organization_last_owner_#{action}" }
    %i[mission_messages mission_applications volunteer_missions organization_invitations partnerships].each { |table| drop_table table }
    remove_check_constraint :feature_flags, name: "feature_flags_key_values"
    add_check_constraint :feature_flags, "key IN ('public_map_enabled','financial_support_enabled')", name: "feature_flags_key_values"
    remove_reference :organizations, :verified_by, foreign_key: { to_table: :users }
    %i[description public_location legal_name registration_number legal_email published_at verified_at lock_version].each { |column| remove_column :organizations, column }
  end
end
