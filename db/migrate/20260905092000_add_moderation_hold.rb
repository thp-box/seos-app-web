class AddModerationHold < ActiveRecord::Migration[8.1]
  def change
    add_column :listings, :moderation_hold, :boolean, null: false, default: false
  end
end
