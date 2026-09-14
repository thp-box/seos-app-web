class CreateDiscoveryAndExchanges < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :public_slug, null: false, index: { unique: true }
      t.string :display_name, null: false
      t.text :bio
      t.string :public_city, :skills, :languages
      t.text :phone, :address_line
      t.string :phone_sharing_policy, null: false, default: "per_exchange"
      t.string :status, null: false, default: "draft"
      t.timestamps
    end
    choices :profiles, :status, %w[draft published restricted anonymized]
    choices :profiles, :phone_sharing_policy, %w[per_exchange nobody]
    create_table :categories do |t|
      t.references :parent, foreign_key: { to_table: :categories }
      t.string :name, :slug, null: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.boolean :sensitive, null: false, default: false
      t.timestamps
    end
    add_index :categories, :slug, unique: true
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
    choices :category_restrictions, :existing_action, %w[review pause]
    create_table :listings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :organization, foreign_key: true
      t.references :category, foreign_key: true
      t.string :slug, null: false, index: { unique: true }
      t.string :title
      t.text :description, :availability, :address_line
      t.string :intent, null: false, default: "offer"
      t.string :exchange_mode, null: false, default: "gift"
      t.integer :estimated_points
      t.string :service_location_mode, null: false, default: "in_person"
      t.string :city
      t.float :latitude, :longitude
      t.string :priority, null: false, default: "standard"
      t.string :status, null: false, default: "draft"
      t.integer :wizard_step, null: false, default: 1
      t.integer :lock_version, null: false, default: 0
      t.datetime :published_at, :closed_at, :removed_at
      t.timestamps
    end
    choices :listings, :intent, %w[offer request]
    choices :listings, :exchange_mode, %w[gift barter points]
    choices :listings, :service_location_mode, %w[in_person remote hybrid]
    choices :listings, :status, %w[draft pending_review published paused closed removed]
    choices :listings, :priority, %w[standard urgent]
    add_check_constraint :listings, "(exchange_mode = 'points' AND (estimated_points IS NULL OR estimated_points > 0)) OR (exchange_mode != 'points' AND estimated_points IS NULL)", name: "listing_points_mode"
    add_index :listings, [ :status, :published_at, :id ]
    create_table :feature_flags do |t|
      t.string :key, null: false, index: { unique: true }
      t.boolean :enabled, null: false, default: true
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    choices :feature_flags, :key, %w[public_map_enabled]
    create_table :service_requests do |t|
      t.references :listing, null: false, foreign_key: true
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :provider, null: false, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "pending"
      t.json :agreement, null: false, default: {}
      t.integer :agreement_version, null: false, default: 0
      t.references :proposed_by, foreign_key: { to_table: :users }
      t.datetime :requester_agreed_at, :provider_agreed_at
      t.datetime :requester_confirmed_at, :provider_confirmed_at, :completed_at
      t.datetime :requester_shared_at, :provider_shared_at
      t.datetime :expires_at, null: false
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end
    choices :service_requests, :status, %w[pending accepted declined scheduled awaiting_confirmation completed cancelled disputed expired]
    add_check_constraint :service_requests, "requester_id != provider_id", name: "different_participants"
    add_index :service_requests, [ :listing_id, :requester_id ], unique: true,
      where: "status IN ('pending','accepted','scheduled','awaiting_confirmation','disputed')", name: "unique_open_service_request"
    create_table :request_events do |t|
      t.references :service_request, null: false, foreign_key: true
      t.references :actor, null: false, foreign_key: { to_table: :users }
      t.string :kind, null: false
      t.text :details
      t.datetime :created_at, null: false
    end
    create_table :messages do |t|
      t.references :service_request, null: false, foreign_key: true
      t.references :sender, null: false, foreign_key: { to_table: :users }
      t.text :body, null: false
      t.string :delivery_key, null: false
      t.datetime :read_at, :removed_at
      t.timestamps
    end
    add_index :messages, [ :sender_id, :delivery_key ], unique: true
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :service_request, foreign_key: true
      t.string :event_key, null: false
      t.string :title, null: false
      t.datetime :read_at
      t.timestamps
    end
    add_index :notifications, [ :user_id, :event_key ], unique: true
    add_column :users, :email_notifications, :boolean, null: false, default: true
    create_table :user_blocks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :blocked_user, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :user_blocks, [ :user_id, :blocked_user_id ], unique: true
    add_check_constraint :user_blocks, "user_id != blocked_user_id", name: "no_self_block"
    create_table :favorites do |t|
      t.references :user, null: false, foreign_key: true
      t.references :listing, null: false, foreign_key: true
      t.timestamps
    end
    add_index :favorites, [ :user_id, :listing_id ], unique: true
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :listing, null: false, foreign_key: true
      t.text :body, null: false
      t.datetime :removed_at
      t.timestamps
    end
    create_table :reviews do |t|
      t.references :service_request, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.references :reviewee, null: false, foreign_key: { to_table: :users }
      t.string :completion_answer, null: false
      t.boolean :would_reengage, null: false
      t.text :factual_body, :response
      t.datetime :reveal_at, null: false
      t.datetime :removed_at, :invalidated_at
      t.timestamps
    end
    choices :reviews, :completion_answer, %w[yes partially no]
    add_index :reviews, [ :service_request_id, :author_id ], unique: true
    create_table :review_criteria do |t|
      t.references :category, foreign_key: true
      t.string :key, null: false
      t.string :label, null: false
      t.string :evaluator_role, null: false, default: "both"
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :review_criteria, :key, unique: true
    choices :review_criteria, :evaluator_role, %w[both requester provider]
    create_table :review_ratings do |t|
      t.references :review, null: false, foreign_key: true
      t.references :review_criterion, null: false, foreign_key: { to_table: :review_criteria }
      t.string :label_snapshot, null: false
      t.integer :rating
      t.boolean :not_applicable, null: false, default: false
      t.timestamps
    end
    add_index :review_ratings, [ :review_id, :review_criterion_id ], unique: true, name: "unique_review_rating"
    add_check_constraint :review_ratings, "(not_applicable = 1 AND rating IS NULL) OR (not_applicable = 0 AND rating BETWEEN 1 AND 5 AND rating IS NOT NULL)", name: "rating_or_na"
    create_table :reports do |t|
      t.references :reporter, null: false, foreign_key: { to_table: :users }
      t.references :reportable, null: false, polymorphic: true
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.string :reason, null: false
      t.text :details, :resolution
      t.string :status, null: false, default: "open"
      t.datetime :due_at, null: false
      t.datetime :resolved_at
      t.timestamps
    end
    choices :reports, :status, %w[open investigating resolved]
    choices :reports, :reportable_type, %w[Listing Profile Message Comment Review ServiceRequest]
    create_table :content_versions do |t|
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :kind, :slug, :title, null: false
      t.string :summary
      t.text :body, null: false
      t.integer :version, null: false
      t.datetime :published_at, :archived_at
      t.json :decorations, null: false, default: []
      t.timestamps
    end
    choices :content_versions, :kind, %w[page article legal]
    add_index :content_versions, [ :kind, :slug, :version ], unique: true
    create_table :contact_requests do |t|
      t.text :email, :message, null: false
      t.string :subject, null: false
      t.string :status, null: false, default: "open"
      t.datetime :resolved_at
      t.timestamps
    end
  end

  def choices(table, column, values)
    add_check_constraint table, "#{column} IN (#{values.map { |value| connection.quote(value) }.join(',')})", name: "#{table}_#{column}_values"
  end
end
