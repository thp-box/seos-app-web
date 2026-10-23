class ReplacePartnershipsWithEditorialPage < ActiveRecord::Migration[8.1]
  def up
    create_table :partnership_pages do |t|
      t.string :title, null: false
      t.text :introduction
      t.text :body
      t.string :contact_label
      t.string :contact_url
      t.references :updated_by, foreign_key: { to_table: :users }
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    drop_table :partnerships
    execute "UPDATE organizations SET request_kind = 'community_mission' WHERE request_kind = 'partnership'"
    execute "DELETE FROM feature_flags WHERE key = 'partnerships_enabled'"
    add_column :help_chains, :featured_on_home, :boolean, null: false, default: false
  end

  def down
    remove_column :help_chains, :featured_on_home
    drop_table :partnership_pages
    create_table :partnerships do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :slug, null: false
      t.string :public_title, null: false
      t.text :public_description
      t.string :kind, null: false, default: "support"
      t.string :status, null: false, default: "draft"
      t.date :starts_on
      t.date :ends_on
      t.string :cta_url
      t.string :cta_label
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :partnerships, :slug, unique: true
  end
end
