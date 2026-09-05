CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "users" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "email" varchar COLLATE "NOCASE" NOT NULL, "encrypted_password" varchar DEFAULT '' NOT NULL, "role" varchar DEFAULT 'member' NOT NULL, "status" varchar DEFAULT 'pending' NOT NULL, "reset_password_token" varchar, "reset_password_sent_at" datetime(6), "confirmation_token" varchar, "confirmed_at" datetime(6), "confirmation_sent_at" datetime(6), "unconfirmed_email" varchar, "failed_attempts" integer DEFAULT 0 NOT NULL, "locked_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT users_role CHECK (role IN ('member', 'admin', 'super_admin')), CONSTRAINT users_status CHECK (status IN ('pending', 'active', 'suspended', 'anonymized')), CONSTRAINT users_normalized_email CHECK (email = lower(trim(email)) AND length(email) > 0));
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
INSERT INTO "schema_migrations" (version) VALUES
('20260905123500'),
('20260905123456'),
('20260905123455');

