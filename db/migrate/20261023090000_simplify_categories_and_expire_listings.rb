class SimplifyCategoriesAndExpireListings < ActiveRecord::Migration[8.1]
  def up
    add_column :categories, :deleted_at, :datetime
    add_index :categories, :deleted_at
    add_column :listings, :expires_at, :datetime
    add_index :listings, [ :status, :expires_at ]

    execute <<~SQL.squish
      UPDATE listings
      SET expires_at = datetime(COALESCE(published_at, created_at), '+1 year')
      WHERE status = 'published'
    SQL

    drop_table :category_restrictions
  end

  def down
    create_table :category_restrictions do |t|
      t.references :category, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }, null: false
      t.string :term
      t.string :reason, null: false
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.boolean :active, null: false, default: true
      t.string :existing_action, null: false, default: "review"
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    add_check_constraint :category_restrictions, "existing_action IN ('review','pause')", name: "category_restrictions_existing_action_values"

    remove_index :listings, [ :status, :expires_at ]
    remove_column :listings, :expires_at
    remove_index :categories, :deleted_at
    remove_column :categories, :deleted_at
  end
end
