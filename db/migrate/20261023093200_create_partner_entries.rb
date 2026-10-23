class CreatePartnerEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :partner_entries do |t|
      t.references :partnership_page, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.string :website_url, null: false
      t.integer :position, null: false, default: 0
      t.timestamps
    end

    add_index :partner_entries, [ :partnership_page_id, :position ]
  end
end
