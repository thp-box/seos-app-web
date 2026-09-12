class CategorizeNotifications < ActiveRecord::Migration[8.1]
  def up
    add_column :notifications, :category, :string, null: false, default: "general"
    add_index :notifications, [ :user_id, :read_at, :category ], name: "notification_unread_categories"
    execute <<~SQL
      UPDATE notifications SET category = CASE
        WHEN event_key LIKE 'message:%' OR event_key LIKE 'exchange:%' THEN 'messages'
        WHEN event_key LIKE 'review:%' THEN 'reviews'
        WHEN event_key LIKE 'achievement:%' THEN 'quests'
        WHEN event_key LIKE 'points:%' THEN 'wallet'
        WHEN event_key LIKE 'top:%' THEN 'quests'
        WHEN event_key LIKE 'testimonial:%' THEN 'testimonials'
        WHEN event_key LIKE 'referral:%' OR event_key LIKE 'trust:%' THEN 'trust'
        WHEN event_key LIKE 'chain:%' THEN 'chains'
        WHEN event_key LIKE 'mission:%' THEN 'missions'
        WHEN event_key LIKE 'restriction:%' THEN 'listings'
        ELSE 'general' END
    SQL
  end

  def down
    remove_index :notifications, name: "notification_unread_categories"
    remove_column :notifications, :category
  end
end
