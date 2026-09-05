CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "users" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "email" varchar COLLATE "NOCASE" NOT NULL, "encrypted_password" varchar DEFAULT '' NOT NULL, "role" varchar DEFAULT 'member' NOT NULL, "status" varchar DEFAULT 'pending' NOT NULL, "reset_password_token" varchar, "reset_password_sent_at" datetime(6), "confirmation_token" varchar, "confirmed_at" datetime(6), "confirmation_sent_at" datetime(6), "unconfirmed_email" varchar, "failed_attempts" integer DEFAULT 0 NOT NULL, "locked_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "email_notifications" boolean DEFAULT TRUE NOT NULL /*application='SeosFrance'*/, CONSTRAINT users_role CHECK (role IN ('member', 'admin', 'super_admin')), CONSTRAINT users_status CHECK (status IN ('pending', 'active', 'suspended', 'anonymized')), CONSTRAINT users_normalized_email CHECK (email = lower(trim(email)) AND length(email) > 0));
CREATE UNIQUE INDEX "index_users_on_email" ON "users" ("email") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_users_on_confirmation_token" ON "users" ("confirmation_token") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_users_on_reset_password_token" ON "users" ("reset_password_token") /*application='SeosFrance'*/;
CREATE INDEX "index_users_on_role_and_status" ON "users" ("role", "status") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "active_storage_blobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "filename" varchar NOT NULL, "content_type" varchar, "metadata" text, "service_name" varchar NOT NULL, "byte_size" bigint NOT NULL, "checksum" varchar, "created_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_active_storage_blobs_on_key" ON "active_storage_blobs" ("key") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "active_storage_attachments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "record_type" varchar NOT NULL, "record_id" bigint NOT NULL, "blob_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c3b3935057"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE INDEX "index_active_storage_attachments_on_blob_id" ON "active_storage_attachments" ("blob_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_active_storage_attachments_uniqueness" ON "active_storage_attachments" ("record_type", "record_id", "name", "blob_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "active_storage_variant_records" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "variation_digest" varchar NOT NULL, CONSTRAINT "fk_rails_993965df05"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE UNIQUE INDEX "index_active_storage_variant_records_uniqueness" ON "active_storage_variant_records" ("blob_id", "variation_digest") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "login_sessions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "token_digest" varchar NOT NULL, "user_agent_summary" varchar NOT NULL, "last_seen_at" datetime(6) NOT NULL, "expires_at" datetime(6) NOT NULL, "revoked_at" datetime(6), "reauthenticated_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_8c949dd2cd"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_login_sessions_on_user_id" ON "login_sessions" ("user_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_login_sessions_on_token_digest" ON "login_sessions" ("token_digest") /*application='SeosFrance'*/;
CREATE INDEX "index_login_sessions_on_expires_at" ON "login_sessions" ("expires_at") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "admin_permission_grants" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "permission" varchar NOT NULL, "granted_by_id" integer NOT NULL, "granted_at" datetime(6) NOT NULL, "expires_at" datetime(6), "revoked_by_id" integer, "revoked_at" datetime(6), "reason" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_987d863ff8"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_9aa9b70d55"
FOREIGN KEY ("granted_by_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_e6b9e1792b"
FOREIGN KEY ("revoked_by_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_admin_permission_grants_on_user_id" ON "admin_permission_grants" ("user_id") /*application='SeosFrance'*/;
CREATE INDEX "index_admin_permission_grants_on_granted_by_id" ON "admin_permission_grants" ("granted_by_id") /*application='SeosFrance'*/;
CREATE INDEX "index_admin_permission_grants_on_revoked_by_id" ON "admin_permission_grants" ("revoked_by_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "unique_unrevoked_permission" ON "admin_permission_grants" ("user_id", "permission") WHERE revoked_at IS NULL /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "organizations" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "slug" varchar NOT NULL, "kind" varchar NOT NULL, "status" varchar DEFAULT 'pending' NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT organizations_kind CHECK (kind IN ('association', 'company', 'institution', 'collective')), CONSTRAINT organizations_status CHECK (status IN ('pending', 'verified', 'rejected', 'suspended')));
CREATE UNIQUE INDEX "index_organizations_on_slug" ON "organizations" ("slug") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "organization_memberships" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "organization_id" integer NOT NULL, "user_id" integer NOT NULL, "role" varchar NOT NULL, "status" varchar DEFAULT 'active' NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_715ab7f4fe"
FOREIGN KEY ("organization_id")
  REFERENCES "organizations" ("id")
, CONSTRAINT "fk_rails_57cf70d280"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT memberships_role CHECK (role IN ('owner', 'manager', 'editor')), CONSTRAINT memberships_status CHECK (status IN ('active', 'revoked')));
CREATE INDEX "index_organization_memberships_on_organization_id" ON "organization_memberships" ("organization_id") /*application='SeosFrance'*/;
CREATE INDEX "index_organization_memberships_on_user_id" ON "organization_memberships" ("user_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_organization_memberships_on_organization_id_and_user_id" ON "organization_memberships" ("organization_id", "user_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "audit_logs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "actor_id" integer NOT NULL, "target_type" varchar NOT NULL, "target_id" integer NOT NULL, "action" varchar NOT NULL, "reason" varchar NOT NULL, "metadata" json DEFAULT '{}' NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_2c3f85fdd5"
FOREIGN KEY ("actor_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_audit_logs_on_actor_id" ON "audit_logs" ("actor_id") /*application='SeosFrance'*/;
CREATE INDEX "index_audit_logs_on_target" ON "audit_logs" ("target_type", "target_id") /*application='SeosFrance'*/;
CREATE TRIGGER audit_logs_no_update BEFORE UPDATE ON audit_logs BEGIN SELECT RAISE(ABORT, 'audit_logs are append only'); END;
CREATE TRIGGER audit_logs_no_delete BEFORE DELETE ON audit_logs BEGIN SELECT RAISE(ABORT, 'audit_logs are append only'); END;
CREATE TABLE IF NOT EXISTS "profiles" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "public_slug" varchar NOT NULL, "display_name" varchar NOT NULL, "bio" text, "public_city" varchar, "skills" varchar, "languages" varchar, "phone" text, "address_line" text, "phone_sharing_policy" varchar DEFAULT 'per_exchange' NOT NULL, "status" varchar DEFAULT 'draft' NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_e424190865"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT profiles_status_values CHECK (status IN ('draft','published','restricted','anonymized')), CONSTRAINT profiles_phone_sharing_policy_values CHECK (phone_sharing_policy IN ('per_exchange','nobody')));
CREATE UNIQUE INDEX "index_profiles_on_user_id" ON "profiles" ("user_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_profiles_on_public_slug" ON "profiles" ("public_slug") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "categories" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "parent_id" integer, "name" varchar NOT NULL, "slug" varchar NOT NULL, "position" integer DEFAULT 0 NOT NULL, "active" boolean DEFAULT TRUE NOT NULL, "sensitive" boolean DEFAULT FALSE NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_82f48f7407"
FOREIGN KEY ("parent_id")
  REFERENCES "categories" ("id")
);
CREATE INDEX "index_categories_on_parent_id" ON "categories" ("parent_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_categories_on_slug" ON "categories" ("slug") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "category_restrictions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "category_id" integer, "created_by_id" integer NOT NULL, "term" varchar, "reason" varchar NOT NULL, "starts_at" datetime(6) NOT NULL, "ends_at" datetime(6), "active" boolean DEFAULT TRUE NOT NULL, "existing_action" varchar DEFAULT 'review' NOT NULL, "lock_version" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_d2e54ed452"
FOREIGN KEY ("created_by_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_d4026942dc"
FOREIGN KEY ("category_id")
  REFERENCES "categories" ("id")
, CONSTRAINT category_restrictions_existing_action_values CHECK (existing_action IN ('review','pause')));
CREATE INDEX "index_category_restrictions_on_category_id" ON "category_restrictions" ("category_id") /*application='SeosFrance'*/;
CREATE INDEX "index_category_restrictions_on_created_by_id" ON "category_restrictions" ("created_by_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "listings" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "organization_id" integer, "category_id" integer, "slug" varchar NOT NULL, "title" varchar, "description" text, "availability" text, "address_line" text, "intent" varchar DEFAULT 'offer' NOT NULL, "exchange_mode" varchar DEFAULT 'gift' NOT NULL, "estimated_points" integer, "service_location_mode" varchar DEFAULT 'in_person' NOT NULL, "city" varchar, "latitude" float, "longitude" float, "priority" varchar DEFAULT 'standard' NOT NULL, "status" varchar DEFAULT 'draft' NOT NULL, "wizard_step" integer DEFAULT 1 NOT NULL, "lock_version" integer DEFAULT 0 NOT NULL, "published_at" datetime(6), "closed_at" datetime(6), "removed_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "moderation_hold" boolean DEFAULT FALSE NOT NULL /*application='SeosFrance'*/, CONSTRAINT "fk_rails_baa008bfd2"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_e41ea99bf4"
FOREIGN KEY ("organization_id")
  REFERENCES "organizations" ("id")
, CONSTRAINT "fk_rails_a855f030e2"
FOREIGN KEY ("category_id")
  REFERENCES "categories" ("id")
, CONSTRAINT listings_intent_values CHECK (intent IN ('offer','request')), CONSTRAINT listings_exchange_mode_values CHECK (exchange_mode IN ('gift','barter','points')), CONSTRAINT listings_service_location_mode_values CHECK (service_location_mode IN ('in_person','remote','hybrid')), CONSTRAINT listings_status_values CHECK (status IN ('draft','pending_review','published','paused','closed','removed')), CONSTRAINT listings_priority_values CHECK (priority IN ('standard','urgent')), CONSTRAINT listing_points_mode CHECK ((exchange_mode = 'points' AND (estimated_points IS NULL OR estimated_points > 0)) OR (exchange_mode != 'points' AND estimated_points IS NULL)));
CREATE INDEX "index_listings_on_user_id" ON "listings" ("user_id") /*application='SeosFrance'*/;
CREATE INDEX "index_listings_on_organization_id" ON "listings" ("organization_id") /*application='SeosFrance'*/;
CREATE INDEX "index_listings_on_category_id" ON "listings" ("category_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_listings_on_slug" ON "listings" ("slug") /*application='SeosFrance'*/;
CREATE INDEX "index_listings_on_status_and_published_at_and_id" ON "listings" ("status", "published_at", "id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "feature_flags" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "enabled" boolean DEFAULT TRUE NOT NULL, "lock_version" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT feature_flags_key_values CHECK (key IN ('public_map_enabled')));
CREATE UNIQUE INDEX "index_feature_flags_on_key" ON "feature_flags" ("key") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "service_requests" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "listing_id" integer NOT NULL, "requester_id" integer NOT NULL, "provider_id" integer NOT NULL, "status" varchar DEFAULT 'pending' NOT NULL, "agreement" json DEFAULT '{}' NOT NULL, "agreement_version" integer DEFAULT 0 NOT NULL, "proposed_by_id" integer, "requester_agreed_at" datetime(6), "provider_agreed_at" datetime(6), "requester_confirmed_at" datetime(6), "provider_confirmed_at" datetime(6), "completed_at" datetime(6), "requester_shared_at" datetime(6), "provider_shared_at" datetime(6), "expires_at" datetime(6) NOT NULL, "lock_version" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_995faf1178"
FOREIGN KEY ("listing_id")
  REFERENCES "listings" ("id")
, CONSTRAINT "fk_rails_8205161223"
FOREIGN KEY ("requester_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_fea6702d40"
FOREIGN KEY ("provider_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_74017f43f9"
FOREIGN KEY ("proposed_by_id")
  REFERENCES "users" ("id")
, CONSTRAINT service_requests_status_values CHECK (status IN ('pending','accepted','declined','scheduled','awaiting_confirmation','completed','cancelled','disputed','expired')), CONSTRAINT different_participants CHECK (requester_id != provider_id));
CREATE INDEX "index_service_requests_on_listing_id" ON "service_requests" ("listing_id") /*application='SeosFrance'*/;
CREATE INDEX "index_service_requests_on_requester_id" ON "service_requests" ("requester_id") /*application='SeosFrance'*/;
CREATE INDEX "index_service_requests_on_provider_id" ON "service_requests" ("provider_id") /*application='SeosFrance'*/;
CREATE INDEX "index_service_requests_on_proposed_by_id" ON "service_requests" ("proposed_by_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "unique_open_service_request" ON "service_requests" ("listing_id", "requester_id") WHERE status IN ('pending','accepted','scheduled','awaiting_confirmation','disputed') /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "request_events" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "service_request_id" integer NOT NULL, "actor_id" integer NOT NULL, "kind" varchar NOT NULL, "details" text, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_808b383ff4"
FOREIGN KEY ("service_request_id")
  REFERENCES "service_requests" ("id")
, CONSTRAINT "fk_rails_6d9c6cb794"
FOREIGN KEY ("actor_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_request_events_on_service_request_id" ON "request_events" ("service_request_id") /*application='SeosFrance'*/;
CREATE INDEX "index_request_events_on_actor_id" ON "request_events" ("actor_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "messages" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "service_request_id" integer NOT NULL, "sender_id" integer NOT NULL, "body" text NOT NULL, "delivery_key" varchar NOT NULL, "read_at" datetime(6), "removed_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_88e79e38c5"
FOREIGN KEY ("service_request_id")
  REFERENCES "service_requests" ("id")
, CONSTRAINT "fk_rails_b8f26a382d"
FOREIGN KEY ("sender_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_messages_on_service_request_id" ON "messages" ("service_request_id") /*application='SeosFrance'*/;
CREATE INDEX "index_messages_on_sender_id" ON "messages" ("sender_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_messages_on_sender_id_and_delivery_key" ON "messages" ("sender_id", "delivery_key") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "notifications" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "service_request_id" integer, "event_key" varchar NOT NULL, "title" varchar NOT NULL, "read_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "emailed_at" datetime(6) /*application='SeosFrance'*/, CONSTRAINT "fk_rails_b080fb4855"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_f6d7cf0913"
FOREIGN KEY ("service_request_id")
  REFERENCES "service_requests" ("id")
);
CREATE INDEX "index_notifications_on_user_id" ON "notifications" ("user_id") /*application='SeosFrance'*/;
CREATE INDEX "index_notifications_on_service_request_id" ON "notifications" ("service_request_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_notifications_on_user_id_and_event_key" ON "notifications" ("user_id", "event_key") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "user_blocks" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "blocked_user_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_5e2a3658fd"
FOREIGN KEY ("blocked_user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_d98a90b4c8"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT no_self_block CHECK (user_id != blocked_user_id));
CREATE INDEX "index_user_blocks_on_user_id" ON "user_blocks" ("user_id") /*application='SeosFrance'*/;
CREATE INDEX "index_user_blocks_on_blocked_user_id" ON "user_blocks" ("blocked_user_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_user_blocks_on_user_id_and_blocked_user_id" ON "user_blocks" ("user_id", "blocked_user_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "favorites" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "listing_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_d15744e438"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_356df97f97"
FOREIGN KEY ("listing_id")
  REFERENCES "listings" ("id")
);
CREATE INDEX "index_favorites_on_user_id" ON "favorites" ("user_id") /*application='SeosFrance'*/;
CREATE INDEX "index_favorites_on_listing_id" ON "favorites" ("listing_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_favorites_on_user_id_and_listing_id" ON "favorites" ("user_id", "listing_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "comments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "listing_id" integer NOT NULL, "body" text NOT NULL, "removed_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_03de2dc08c"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_a71be3ac94"
FOREIGN KEY ("listing_id")
  REFERENCES "listings" ("id")
);
CREATE INDEX "index_comments_on_user_id" ON "comments" ("user_id") /*application='SeosFrance'*/;
CREATE INDEX "index_comments_on_listing_id" ON "comments" ("listing_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "reviews" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "service_request_id" integer NOT NULL, "author_id" integer NOT NULL, "reviewee_id" integer NOT NULL, "completion_answer" varchar NOT NULL, "would_reengage" boolean NOT NULL, "factual_body" text, "response" text, "reveal_at" datetime(6) NOT NULL, "removed_at" datetime(6), "invalidated_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_6c8f877405"
FOREIGN KEY ("reviewee_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_29e6f859c4"
FOREIGN KEY ("author_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_4413178d93"
FOREIGN KEY ("service_request_id")
  REFERENCES "service_requests" ("id")
, CONSTRAINT reviews_completion_answer_values CHECK (completion_answer IN ('yes','partially','no')));
CREATE INDEX "index_reviews_on_service_request_id" ON "reviews" ("service_request_id") /*application='SeosFrance'*/;
CREATE INDEX "index_reviews_on_author_id" ON "reviews" ("author_id") /*application='SeosFrance'*/;
CREATE INDEX "index_reviews_on_reviewee_id" ON "reviews" ("reviewee_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_reviews_on_service_request_id_and_author_id" ON "reviews" ("service_request_id", "author_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "review_criteria" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "category_id" integer, "key" varchar NOT NULL, "label" varchar NOT NULL, "evaluator_role" varchar DEFAULT 'both' NOT NULL, "active" boolean DEFAULT TRUE NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_4b63e8573f"
FOREIGN KEY ("category_id")
  REFERENCES "categories" ("id")
, CONSTRAINT review_criteria_evaluator_role_values CHECK (evaluator_role IN ('both','requester','provider')));
CREATE INDEX "index_review_criteria_on_category_id" ON "review_criteria" ("category_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_review_criteria_on_key" ON "review_criteria" ("key") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "review_ratings" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "review_id" integer NOT NULL, "review_criterion_id" integer NOT NULL, "label_snapshot" varchar NOT NULL, "rating" integer, "not_applicable" boolean DEFAULT FALSE NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "dimension_snapshot" varchar /*application='SeosFrance'*/, CONSTRAINT "fk_rails_f692c34694"
FOREIGN KEY ("review_criterion_id")
  REFERENCES "review_criteria" ("id")
, CONSTRAINT "fk_rails_8948e4ab9e"
FOREIGN KEY ("review_id")
  REFERENCES "reviews" ("id")
, CONSTRAINT rating_or_na CHECK ((not_applicable = 1 AND rating IS NULL) OR (not_applicable = 0 AND rating BETWEEN 1 AND 5 AND rating IS NOT NULL)));
CREATE INDEX "index_review_ratings_on_review_id" ON "review_ratings" ("review_id") /*application='SeosFrance'*/;
CREATE INDEX "index_review_ratings_on_review_criterion_id" ON "review_ratings" ("review_criterion_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "unique_review_rating" ON "review_ratings" ("review_id", "review_criterion_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "reports" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "reporter_id" integer NOT NULL, "reportable_type" varchar NOT NULL, "reportable_id" integer NOT NULL, "assigned_to_id" integer, "reason" varchar NOT NULL, "details" text, "resolution" text, "status" varchar DEFAULT 'open' NOT NULL, "due_at" datetime(6) NOT NULL, "resolved_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c4cb6e6463"
FOREIGN KEY ("reporter_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_96d456023d"
FOREIGN KEY ("assigned_to_id")
  REFERENCES "users" ("id")
, CONSTRAINT reports_status_values CHECK (status IN ('open','investigating','resolved')), CONSTRAINT reports_reportable_type_values CHECK (reportable_type IN ('Listing','Profile','Message','Comment','Review','ServiceRequest')));
CREATE INDEX "index_reports_on_reporter_id" ON "reports" ("reporter_id") /*application='SeosFrance'*/;
CREATE INDEX "index_reports_on_reportable" ON "reports" ("reportable_type", "reportable_id") /*application='SeosFrance'*/;
CREATE INDEX "index_reports_on_assigned_to_id" ON "reports" ("assigned_to_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "content_versions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "author_id" integer NOT NULL, "kind" varchar NOT NULL, "slug" varchar NOT NULL, "title" varchar NOT NULL, "summary" varchar, "body" text NOT NULL, "version" integer NOT NULL, "published_at" datetime(6), "archived_at" datetime(6), "decorations" json DEFAULT '[]' NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_4272400340"
FOREIGN KEY ("author_id")
  REFERENCES "users" ("id")
, CONSTRAINT content_versions_kind_values CHECK (kind IN ('page','article','legal')));
CREATE INDEX "index_content_versions_on_author_id" ON "content_versions" ("author_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_content_versions_on_kind_and_slug_and_version" ON "content_versions" ("kind", "slug", "version") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "contact_requests" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "email" text NOT NULL, "message" text NOT NULL, "subject" varchar NOT NULL, "status" varchar DEFAULT 'open' NOT NULL, "resolved_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TRIGGER request_events_no_update BEFORE UPDATE ON request_events BEGIN SELECT RAISE(ABORT, 'request history is append-only'); END;
CREATE TRIGGER request_events_no_delete BEFORE DELETE ON request_events BEGIN SELECT RAISE(ABORT, 'request history is append-only'); END;
CREATE TRIGGER published_content_no_update BEFORE UPDATE ON content_versions WHEN OLD.published_at IS NOT NULL BEGIN SELECT RAISE(ABORT, 'published content is immutable'); END;
CREATE TRIGGER published_content_no_delete BEFORE DELETE ON content_versions WHEN OLD.published_at IS NOT NULL BEGIN SELECT RAISE(ABORT, 'published content is immutable'); END;
CREATE TABLE IF NOT EXISTS "referral_exemptions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "granted_by_id" integer NOT NULL, "reason" text NOT NULL, "expires_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_f52d65295b"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_1859fb3ba5"
FOREIGN KEY ("granted_by_id")
  REFERENCES "users" ("id")
);
CREATE UNIQUE INDEX "index_referral_exemptions_on_user_id" ON "referral_exemptions" ("user_id") /*application='SeosFrance'*/;
CREATE INDEX "index_referral_exemptions_on_granted_by_id" ON "referral_exemptions" ("granted_by_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "referral_codes" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "owner_id" integer NOT NULL, "code_digest" varchar NOT NULL, "expires_at" datetime(6) NOT NULL, "claimed_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_271698188c"
FOREIGN KEY ("owner_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_referral_codes_on_owner_id" ON "referral_codes" ("owner_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_referral_codes_on_code_digest" ON "referral_codes" ("code_digest") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "referrals" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "referral_code_id" integer NOT NULL, "referrer_id" integer NOT NULL, "referred_user_id" integer NOT NULL, "position" integer NOT NULL, "primary_referrer" boolean DEFAULT FALSE NOT NULL, "status" varchar DEFAULT 'provisional' NOT NULL, "claimed_at" datetime(6) NOT NULL, "objection_deadline_at" datetime(6) NOT NULL, "confirmed_at" datetime(6), "qualified_at" datetime(6), "invalidated_at" datetime(6), "invalidation_reason" text, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c65f8d2b8d"
FOREIGN KEY ("referred_user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_2eb0614166"
FOREIGN KEY ("referrer_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_857fbada99"
FOREIGN KEY ("referral_code_id")
  REFERENCES "referral_codes" ("id")
, CONSTRAINT referral_position_range CHECK (position BETWEEN 1 AND 10), CONSTRAINT no_self_referral CHECK (referrer_id != referred_user_id), CONSTRAINT referral_status CHECK (status IN ('provisional', 'confirmed', 'objected', 'invalidated')));
CREATE UNIQUE INDEX "index_referrals_on_referral_code_id" ON "referrals" ("referral_code_id") /*application='SeosFrance'*/;
CREATE INDEX "index_referrals_on_referrer_id" ON "referrals" ("referrer_id") /*application='SeosFrance'*/;
CREATE INDEX "index_referrals_on_referred_user_id" ON "referrals" ("referred_user_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_referrals_on_referrer_id_and_referred_user_id" ON "referrals" ("referrer_id", "referred_user_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_referrals_on_referred_user_id_and_position" ON "referrals" ("referred_user_id", "position") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "one_primary_referrer" ON "referrals" ("referred_user_id") WHERE primary_referrer = 1 /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "trust_algorithm_versions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "version" varchar NOT NULL, "status" varchar DEFAULT 'draft' NOT NULL, "configuration" json DEFAULT '{}' NOT NULL, "explanation" text NOT NULL, "simulation" json DEFAULT '{}' NOT NULL, "created_by_id" integer NOT NULL, "approved_by_id" integer, "activated_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_cd3a97a171"
FOREIGN KEY ("created_by_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_36d0e49a8b"
FOREIGN KEY ("approved_by_id")
  REFERENCES "users" ("id")
);
CREATE UNIQUE INDEX "index_trust_algorithm_versions_on_version" ON "trust_algorithm_versions" ("version") /*application='SeosFrance'*/;
CREATE INDEX "index_trust_algorithm_versions_on_created_by_id" ON "trust_algorithm_versions" ("created_by_id") /*application='SeosFrance'*/;
CREATE INDEX "index_trust_algorithm_versions_on_approved_by_id" ON "trust_algorithm_versions" ("approved_by_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "one_active_trust_algorithm" ON "trust_algorithm_versions" ("status") WHERE status = 'active' /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "trust_events" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "subject_id" integer NOT NULL, "actor_id" integer, "service_request_id" integer, "category_id" integer, "source_type" varchar NOT NULL, "source_id" integer NOT NULL, "source_key" varchar NOT NULL, "dimension" varchar NOT NULL, "event_kind" varchar NOT NULL, "normalized_value" float NOT NULL, "occurred_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_8068f5fcaa"
FOREIGN KEY ("category_id")
  REFERENCES "categories" ("id")
, CONSTRAINT "fk_rails_540b24e148"
FOREIGN KEY ("service_request_id")
  REFERENCES "service_requests" ("id")
, CONSTRAINT "fk_rails_563c1bbabb"
FOREIGN KEY ("actor_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_f6f4284964"
FOREIGN KEY ("subject_id")
  REFERENCES "users" ("id")
, CONSTRAINT trust_value_bounds CHECK (normalized_value >= 0 AND normalized_value <= 1));
CREATE INDEX "index_trust_events_on_subject_id" ON "trust_events" ("subject_id") /*application='SeosFrance'*/;
CREATE INDEX "index_trust_events_on_actor_id" ON "trust_events" ("actor_id") /*application='SeosFrance'*/;
CREATE INDEX "index_trust_events_on_service_request_id" ON "trust_events" ("service_request_id") /*application='SeosFrance'*/;
CREATE INDEX "index_trust_events_on_category_id" ON "trust_events" ("category_id") /*application='SeosFrance'*/;
CREATE INDEX "index_trust_events_on_source" ON "trust_events" ("source_type", "source_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_trust_events_on_source_key" ON "trust_events" ("source_key") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "trust_event_corrections" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "trust_event_id" integer NOT NULL, "actor_id" integer NOT NULL, "excluded" boolean NOT NULL, "reason" text NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_cd33d3c8fa"
FOREIGN KEY ("trust_event_id")
  REFERENCES "trust_events" ("id")
, CONSTRAINT "fk_rails_e23dfaa826"
FOREIGN KEY ("actor_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_trust_event_corrections_on_trust_event_id" ON "trust_event_corrections" ("trust_event_id") /*application='SeosFrance'*/;
CREATE INDEX "index_trust_event_corrections_on_actor_id" ON "trust_event_corrections" ("actor_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "trust_score_snapshots" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "trust_algorithm_version_id" integer NOT NULL, "fingerprint" varchar NOT NULL, "result" json DEFAULT '{}' NOT NULL, "contributions" json DEFAULT '[]' NOT NULL, "calculated_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_4ad530ebed"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_96c72217b7"
FOREIGN KEY ("trust_algorithm_version_id")
  REFERENCES "trust_algorithm_versions" ("id")
);
CREATE INDEX "index_trust_score_snapshots_on_user_id" ON "trust_score_snapshots" ("user_id") /*application='SeosFrance'*/;
CREATE INDEX "index_trust_score_snapshots_on_trust_algorithm_version_id" ON "trust_score_snapshots" ("trust_algorithm_version_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "unique_trust_calculation" ON "trust_score_snapshots" ("user_id", "trust_algorithm_version_id", "fingerprint") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "trust_profiles" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "trust_score_snapshot_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_501222d271"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_af4b21c92c"
FOREIGN KEY ("trust_score_snapshot_id")
  REFERENCES "trust_score_snapshots" ("id")
);
CREATE UNIQUE INDEX "index_trust_profiles_on_user_id" ON "trust_profiles" ("user_id") /*application='SeosFrance'*/;
CREATE INDEX "index_trust_profiles_on_trust_score_snapshot_id" ON "trust_profiles" ("trust_score_snapshot_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "trust_risk_assessments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "reviewed_by_id" integer, "signal" varchar NOT NULL, "evidence_count" integer NOT NULL, "status" varchar DEFAULT 'open' NOT NULL, "decision" text, "expires_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_0d803a5542"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_e8b6e10ad1"
FOREIGN KEY ("reviewed_by_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_trust_risk_assessments_on_user_id" ON "trust_risk_assessments" ("user_id") /*application='SeosFrance'*/;
CREATE INDEX "index_trust_risk_assessments_on_reviewed_by_id" ON "trust_risk_assessments" ("reviewed_by_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "one_open_trust_signal" ON "trust_risk_assessments" ("user_id", "signal") WHERE status = 'open' /*application='SeosFrance'*/;
CREATE TRIGGER trust_events_no_update BEFORE UPDATE ON trust_events BEGIN SELECT RAISE(ABORT, 'immutable trust history'); END;
CREATE TRIGGER trust_events_no_delete BEFORE DELETE ON trust_events BEGIN SELECT RAISE(ABORT, 'immutable trust history'); END;
CREATE TRIGGER trust_event_corrections_no_update BEFORE UPDATE ON trust_event_corrections BEGIN SELECT RAISE(ABORT, 'immutable trust history'); END;
CREATE TRIGGER trust_event_corrections_no_delete BEFORE DELETE ON trust_event_corrections BEGIN SELECT RAISE(ABORT, 'immutable trust history'); END;
CREATE TRIGGER trust_score_snapshots_no_update BEFORE UPDATE ON trust_score_snapshots BEGIN SELECT RAISE(ABORT, 'immutable trust history'); END;
CREATE TRIGGER trust_score_snapshots_no_delete BEFORE DELETE ON trust_score_snapshots BEGIN SELECT RAISE(ABORT, 'immutable trust history'); END;
CREATE TRIGGER trust_configuration_immutable BEFORE UPDATE ON trust_algorithm_versions
WHEN NEW.configuration != OLD.configuration OR NEW.version != OLD.version OR NEW.explanation != OLD.explanation OR NEW.created_by_id != OLD.created_by_id
BEGIN SELECT RAISE(ABORT, 'immutable trust configuration'); END;
CREATE TABLE IF NOT EXISTS "trust_appeals" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "trust_score_snapshot_id" integer, "assigned_to_id" integer, "statement" text NOT NULL, "status" varchar DEFAULT 'open' NOT NULL, "decision" text, "decided_at" datetime(6), "response_due_at" datetime(6) NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "referral_id" integer, CONSTRAINT "fk_rails_6dd7ade7f5"
FOREIGN KEY ("referral_id")
  REFERENCES "referrals" ("id")
, CONSTRAINT "fk_rails_b7343a1b90"
FOREIGN KEY ("assigned_to_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_7be91d2974"
FOREIGN KEY ("trust_score_snapshot_id")
  REFERENCES "trust_score_snapshots" ("id")
, CONSTRAINT "fk_rails_cdf38be849"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT one_trust_appeal_source CHECK ((trust_score_snapshot_id IS NOT NULL AND referral_id IS NULL) OR (trust_score_snapshot_id IS NULL AND referral_id IS NOT NULL)));
CREATE INDEX "index_trust_appeals_on_user_id" ON "trust_appeals" ("user_id") /*application='SeosFrance'*/;
CREATE INDEX "index_trust_appeals_on_trust_score_snapshot_id" ON "trust_appeals" ("trust_score_snapshot_id") /*application='SeosFrance'*/;
CREATE INDEX "index_trust_appeals_on_assigned_to_id" ON "trust_appeals" ("assigned_to_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "one_open_trust_appeal" ON "trust_appeals" ("user_id", "trust_score_snapshot_id") WHERE status IN ('open', 'investigating') /*application='SeosFrance'*/;
CREATE INDEX "index_trust_appeals_on_referral_id" ON "trust_appeals" ("referral_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "one_open_referral_appeal" ON "trust_appeals" ("user_id", "referral_id") WHERE status IN ('open', 'investigating') /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "point_rule_versions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "family" varchar NOT NULL, "name" varchar NOT NULL, "status" varchar DEFAULT 'draft' NOT NULL, "configuration" json DEFAULT '{}' NOT NULL, "simulation" json DEFAULT '{}' NOT NULL, "created_by_id" integer, "effective_at" datetime(6) NOT NULL, "published_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_00c410a914"
FOREIGN KEY ("created_by_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_point_rule_versions_on_created_by_id" ON "point_rule_versions" ("created_by_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "unique_point_rule_effective_date" ON "point_rule_versions" ("family", "effective_at") WHERE status = 'published' /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "point_accounts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer, "kind" varchar DEFAULT 'user' NOT NULL, "balance" bigint DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_ecba00bfbc"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT point_account_owner_and_balance CHECK ((kind = 'user' AND user_id IS NOT NULL AND balance >= 0) OR (kind = 'system' AND user_id IS NULL)), CONSTRAINT point_balance_integer CHECK (typeof(balance) = 'integer' AND balance BETWEEN -9000000000000000 AND 9000000000000000));
CREATE UNIQUE INDEX "index_point_accounts_on_user_id" ON "point_accounts" ("user_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "one_point_system_account" ON "point_accounts" ("kind") WHERE kind = 'system' /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "point_operations" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "kind" varchar NOT NULL, "status" varchar DEFAULT 'pending' NOT NULL, "idempotency_key" varchar NOT NULL, "initiator_id" integer, "source_type" varchar NOT NULL, "source_id" integer NOT NULL, "point_rule_version_id" integer, "reversed_operation_id" integer, "reason" text NOT NULL, "committed_at" datetime(6), "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_d169594655"
FOREIGN KEY ("initiator_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_91916a057e"
FOREIGN KEY ("point_rule_version_id")
  REFERENCES "point_rule_versions" ("id")
, CONSTRAINT "fk_rails_210a2d5d94"
FOREIGN KEY ("reversed_operation_id")
  REFERENCES "point_operations" ("id")
);
CREATE UNIQUE INDEX "index_point_operations_on_idempotency_key" ON "point_operations" ("idempotency_key") /*application='SeosFrance'*/;
CREATE INDEX "index_point_operations_on_initiator_id" ON "point_operations" ("initiator_id") /*application='SeosFrance'*/;
CREATE INDEX "index_point_operations_on_source" ON "point_operations" ("source_type", "source_id") /*application='SeosFrance'*/;
CREATE INDEX "index_point_operations_on_point_rule_version_id" ON "point_operations" ("point_rule_version_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_point_operations_on_reversed_operation_id" ON "point_operations" ("reversed_operation_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "point_entries" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "point_operation_id" integer NOT NULL, "point_account_id" integer NOT NULL, "amount" bigint NOT NULL, "balance_after" bigint NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_48c2628b67"
FOREIGN KEY ("point_account_id")
  REFERENCES "point_accounts" ("id")
, CONSTRAINT "fk_rails_3ac7cde98a"
FOREIGN KEY ("point_operation_id")
  REFERENCES "point_operations" ("id")
, CONSTRAINT point_entry_integer CHECK (typeof(amount) = 'integer' AND amount != 0 AND amount BETWEEN -999999 AND 999999));
CREATE INDEX "index_point_entries_on_point_operation_id" ON "point_entries" ("point_operation_id") /*application='SeosFrance'*/;
CREATE INDEX "index_point_entries_on_point_account_id" ON "point_entries" ("point_account_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "one_entry_per_point_account" ON "point_entries" ("point_operation_id", "point_account_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "point_adjustments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "proposed_by_id" integer NOT NULL, "approved_by_id" integer, "amount" integer NOT NULL, "balance_before" bigint NOT NULL, "reason" text NOT NULL, "expires_at" datetime(6) NOT NULL, "point_operation_id" integer, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_4b4d72a9aa"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_7c511c0c51"
FOREIGN KEY ("proposed_by_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_2fd9acf4d5"
FOREIGN KEY ("approved_by_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_515ea9ac1c"
FOREIGN KEY ("point_operation_id")
  REFERENCES "point_operations" ("id")
);
CREATE INDEX "index_point_adjustments_on_user_id" ON "point_adjustments" ("user_id") /*application='SeosFrance'*/;
CREATE INDEX "index_point_adjustments_on_proposed_by_id" ON "point_adjustments" ("proposed_by_id") /*application='SeosFrance'*/;
CREATE INDEX "index_point_adjustments_on_approved_by_id" ON "point_adjustments" ("approved_by_id") /*application='SeosFrance'*/;
CREATE INDEX "index_point_adjustments_on_point_operation_id" ON "point_adjustments" ("point_operation_id") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "point_reward_claims" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "point_rule_version_id" integer NOT NULL, "reviewed_by_id" integer, "kind" varchar NOT NULL, "period_key" varchar NOT NULL, "status" varchar DEFAULT 'pending' NOT NULL, "evidence" text NOT NULL, "decision" text, "level" varchar DEFAULT 'bronze' NOT NULL, "amount" integer NOT NULL, "point_operation_id" integer, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_6204060139"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_ff01c6d643"
FOREIGN KEY ("point_rule_version_id")
  REFERENCES "point_rule_versions" ("id")
, CONSTRAINT "fk_rails_5a88c24255"
FOREIGN KEY ("reviewed_by_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_ea230849e8"
FOREIGN KEY ("point_operation_id")
  REFERENCES "point_operations" ("id")
);
CREATE INDEX "index_point_reward_claims_on_user_id" ON "point_reward_claims" ("user_id") /*application='SeosFrance'*/;
CREATE INDEX "index_point_reward_claims_on_point_rule_version_id" ON "point_reward_claims" ("point_rule_version_id") /*application='SeosFrance'*/;
CREATE INDEX "index_point_reward_claims_on_reviewed_by_id" ON "point_reward_claims" ("reviewed_by_id") /*application='SeosFrance'*/;
CREATE INDEX "index_point_reward_claims_on_point_operation_id" ON "point_reward_claims" ("point_operation_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "unique_point_reward_claim" ON "point_reward_claims" ("user_id", "kind", "period_key") /*application='SeosFrance'*/;
CREATE TABLE IF NOT EXISTS "point_cycle_progresses" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "point_rule_version_id" integer NOT NULL, "cycle_number" integer NOT NULL, "operation_ids" json DEFAULT '[]' NOT NULL, "point_operation_id" integer, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_669415c165"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_495f903596"
FOREIGN KEY ("point_rule_version_id")
  REFERENCES "point_rule_versions" ("id")
, CONSTRAINT "fk_rails_61535e2b0f"
FOREIGN KEY ("point_operation_id")
  REFERENCES "point_operations" ("id")
);
CREATE INDEX "index_point_cycle_progresses_on_user_id" ON "point_cycle_progresses" ("user_id") /*application='SeosFrance'*/;
CREATE INDEX "index_point_cycle_progresses_on_point_rule_version_id" ON "point_cycle_progresses" ("point_rule_version_id") /*application='SeosFrance'*/;
CREATE INDEX "index_point_cycle_progresses_on_point_operation_id" ON "point_cycle_progresses" ("point_operation_id") /*application='SeosFrance'*/;
CREATE UNIQUE INDEX "index_point_cycle_progresses_on_user_id_and_cycle_number" ON "point_cycle_progresses" ("user_id", "cycle_number") /*application='SeosFrance'*/;
CREATE TRIGGER point_entry_insert_guard BEFORE INSERT ON point_entries BEGIN
  SELECT CASE WHEN (SELECT status FROM point_operations WHERE id = NEW.point_operation_id) != 'pending'
    THEN RAISE(ABORT, 'operation already committed') END;
  SELECT CASE WHEN NEW.balance_after != (SELECT balance FROM point_accounts WHERE id = NEW.point_account_id) + NEW.amount
    THEN RAISE(ABORT, 'incorrect resulting balance') END;
END;
CREATE TRIGGER point_entry_balance AFTER INSERT ON point_entries BEGIN
  UPDATE point_accounts SET balance = NEW.balance_after WHERE id = NEW.point_account_id;
END;
CREATE TRIGGER point_balance_derived BEFORE UPDATE ON point_accounts
WHEN NEW.user_id IS NOT OLD.user_id OR NEW.kind != OLD.kind OR NEW.balance != COALESCE((SELECT SUM(amount) FROM point_entries WHERE point_account_id = OLD.id), 0)
BEGIN SELECT RAISE(ABORT, 'balance must follow ledger'); END;
CREATE TRIGGER point_account_initial_zero BEFORE INSERT ON point_accounts
WHEN NEW.balance != 0 BEGIN SELECT RAISE(ABORT, 'account must start at zero'); END;
CREATE TRIGGER point_operation_commit BEFORE UPDATE ON point_operations BEGIN
  SELECT CASE WHEN OLD.status != 'pending' OR NEW.status != 'committed' OR NEW.committed_at IS NULL
    OR NEW.kind != OLD.kind OR NEW.idempotency_key != OLD.idempotency_key OR NEW.reason != OLD.reason
    OR NEW.source_type != OLD.source_type OR NEW.source_id != OLD.source_id
    OR NEW.initiator_id IS NOT OLD.initiator_id OR NEW.point_rule_version_id IS NOT OLD.point_rule_version_id
    OR NEW.reversed_operation_id IS NOT OLD.reversed_operation_id OR NEW.created_at != OLD.created_at
    THEN RAISE(ABORT, 'immutable point operation') END;
  SELECT CASE WHEN (SELECT COUNT(*) FROM point_entries WHERE point_operation_id = OLD.id) != 2
    OR (SELECT COALESCE(SUM(amount), 0) FROM point_entries WHERE point_operation_id = OLD.id) != 0
    THEN RAISE(ABORT, 'unbalanced point operation') END;
END;
CREATE TRIGGER point_operation_starts_pending BEFORE INSERT ON point_operations WHEN NEW.status != 'pending' BEGIN SELECT RAISE(ABORT, 'operation must start pending'); END;
CREATE TRIGGER point_entries_no_update BEFORE UPDATE ON point_entries BEGIN SELECT RAISE(ABORT, 'immutable point entries'); END;
CREATE TRIGGER point_entries_no_delete BEFORE DELETE ON point_entries BEGIN SELECT RAISE(ABORT, 'immutable point entries'); END;
CREATE TRIGGER point_operations_no_delete BEFORE DELETE ON point_operations BEGIN SELECT RAISE(ABORT, 'immutable point operation'); END;
CREATE TRIGGER point_rules_no_update BEFORE UPDATE ON point_rule_versions WHEN OLD.status = 'published' BEGIN SELECT RAISE(ABORT, 'immutable published point rule'); END;
CREATE TRIGGER point_rules_no_delete BEFORE DELETE ON point_rule_versions WHEN OLD.status = 'published' BEGIN SELECT RAISE(ABORT, 'immutable published point rule'); END;
CREATE TRIGGER point_adjustment_inputs_immutable BEFORE UPDATE ON point_adjustments
WHEN NEW.user_id != OLD.user_id OR NEW.proposed_by_id != OLD.proposed_by_id OR NEW.amount != OLD.amount
  OR NEW.balance_before != OLD.balance_before OR NEW.reason != OLD.reason OR NEW.expires_at != OLD.expires_at
  OR OLD.point_operation_id IS NOT NULL
BEGIN SELECT RAISE(ABORT, 'immutable adjustment preview'); END;
CREATE TRIGGER point_claim_inputs_immutable BEFORE UPDATE ON point_reward_claims
WHEN NEW.user_id != OLD.user_id OR NEW.point_rule_version_id != OLD.point_rule_version_id OR NEW.kind != OLD.kind
  OR NEW.period_key != OLD.period_key OR NEW.evidence != OLD.evidence OR NEW.amount != OLD.amount OR NEW.level != OLD.level
  OR OLD.status != 'pending'
BEGIN SELECT RAISE(ABORT, 'immutable reward evidence'); END;
INSERT INTO "schema_migrations" (version) VALUES
('20260905123500'),
('20260905123456'),
('20260905123455'),
('20260905112000'),
('20260905111000'),
('20260905110000'),
('20260905102000'),
('20260905101000'),
('20260905100000'),
('20260905093000'),
('20260905092000'),
('20260905091000'),
('20260905090000');

