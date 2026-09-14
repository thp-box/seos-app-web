class CreateMailDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :mail_deliveries do |t|
      t.string :message_id, null: false
      t.string :status, null: false, default: "uncertain"
      t.string :provider_id
      t.timestamps
    end
    add_index :mail_deliveries, :message_id, unique: true
  end
end
