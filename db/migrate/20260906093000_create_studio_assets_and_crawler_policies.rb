class CreateStudioAssetsAndCrawlerPolicies < ActiveRecord::Migration[8.1]
  def change
    create_table :studio_assets do |t|
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    create_table :crawler_policies do |t|
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.boolean :search_enabled, null: false, default: true
      t.boolean :training_enabled, null: false, default: false
      t.timestamps
    end
  end
end
