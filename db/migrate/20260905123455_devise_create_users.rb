class DeviseCreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, collation: "NOCASE"
      t.string :encrypted_password, null: false, default: ""
      t.string :role, null: false, default: "member"
      t.string :status, null: false, default: "pending"
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.string :confirmation_token
      t.datetime :confirmed_at
      t.datetime :confirmation_sent_at
      t.string :unconfirmed_email
      t.integer :failed_attempts, null: false, default: 0
      t.datetime :locked_at
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :confirmation_token, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, [ :role, :status ]
    add_check_constraint :users, "role IN ('member', 'admin', 'super_admin')", name: "users_role"
    add_check_constraint :users, "status IN ('pending', 'active', 'suspended', 'anonymized')", name: "users_status"
    add_check_constraint :users, "email = lower(trim(email)) AND length(email) > 0", name: "users_normalized_email"
  end
end
