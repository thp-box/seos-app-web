class User < ApplicationRecord
  has_one :trust_profile, dependent: :restrict_with_exception
  has_one :profile, dependent: :restrict_with_exception
  has_many :listings, dependent: :restrict_with_exception
  has_many :notifications, dependent: :restrict_with_exception
  has_many :favorites, dependent: :restrict_with_exception

  devise :database_authenticatable, :registerable, :recoverable, :validatable,
    :confirmable, :lockable, :timeoutable, :omniauthable, omniauth_providers: [ :google_oauth2 ]

  enum :role, { member: "member", admin: "admin", super_admin: "super_admin" }, validate: true
  enum :status, { pending: "pending", active: "active", suspended: "suspended", anonymized: "anonymized" }, validate: true

  has_many :login_sessions, dependent: :restrict_with_exception
  has_many :admin_permission_grants, dependent: :restrict_with_exception
  has_many :organization_memberships, dependent: :restrict_with_exception
  has_many :organizations, through: :organization_memberships

  after_update :revoke_sessions_after_password_change

  normalizes :email, with: ->(email) { email.strip.downcase }

  def active_for_authentication?
    super && active? && !LoginBlock.blocked?(email)
  end

  def inactive_message
    suspended? || anonymized? ? :inactive : super
  end

  ADMIN_CORE_PERMISSIONS = %w[listings.moderate organizations.read organizations.manage partnerships.manage].freeze
  SITE_SUPER_ADMIN_PERMISSIONS = %w[content.manage categories.manage studio.read studio.preview studio.manage seo.manage].freeze

  def permission?(key)
    return false unless active? && confirmed?
    return true if super_admin?
    return false unless admin?
    return false if SITE_SUPER_ADMIN_PERMISSIONS.include?(key)
    ADMIN_CORE_PERMISSIONS.include?(key) || admin_permission_grants.effective.exists?(permission: key)
  end

  def administrative?
    active? && confirmed? && (admin? || super_admin?)
  end

  def masked_email
    "#{email.first}***@***"
  end

  private

  def revoke_sessions_after_password_change
    return unless saved_change_to_encrypted_password?
    login_sessions.active.update_all(revoked_at: Time.current)
    Notification.notify!(user: self, key: "security:password:#{id}:#{updated_at.to_f}", title: "Le mot de passe de votre compte a été modifié.", category: "security") if active? && confirmed?
  end

  protected

  def after_confirmation
    update!(status: :active) if pending?
    Referrals.activate_pending!(self) if pending_referral_link_id
  end
end
