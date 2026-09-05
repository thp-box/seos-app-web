class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :validatable,
    :confirmable, :lockable, :timeoutable

  enum :role, { member: "member", admin: "admin", super_admin: "super_admin" }, validate: true
  enum :status, { pending: "pending", active: "active", suspended: "suspended", anonymized: "anonymized" }, validate: true

  has_many :login_sessions, dependent: :restrict_with_exception
  has_many :admin_permission_grants, dependent: :restrict_with_exception
  has_many :organization_memberships, dependent: :restrict_with_exception
  has_many :organizations, through: :organization_memberships

  after_update :revoke_sessions_after_password_change

  normalizes :email, with: ->(email) { email.strip.downcase }

  def active_for_authentication?
    super && active?
  end

  def inactive_message
    suspended? || anonymized? ? :inactive : super
  end

  def permission?(key)
    active? && confirmed? && (super_admin? || (admin? && admin_permission_grants.effective.exists?(permission: key)))
  end

  def administrative?
    active? && confirmed? && (admin? || super_admin?)
  end

  def masked_email
    "#{email.first}***@***"
  end

  private

  def revoke_sessions_after_password_change
    login_sessions.active.update_all(revoked_at: Time.current) if saved_change_to_encrypted_password?
  end

  protected

  def after_confirmation
    update!(status: :active) if pending?
  end
end
