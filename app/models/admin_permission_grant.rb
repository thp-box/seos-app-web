class AdminPermissionGrant < ApplicationRecord
  PERMISSIONS = %w[users.read audit.read content.manage studio.read studio.preview categories.manage listings.moderate exchanges.support reports.manage trust.read trust.manage trust.risk].freeze
  belongs_to :user
  belongs_to :granted_by, class_name: "User"
  belongs_to :revoked_by, class_name: "User", optional: true
  scope :effective, -> { where(revoked_at: nil).where("expires_at IS NULL OR expires_at > ?", Time.current) }
  validates :permission, inclusion: { in: PERMISSIONS }
  validates :reason, presence: true, length: { maximum: 500 }
  validates :granted_at, presence: true
  validate :administrative_user

  private

  def administrative_user
    errors.add(:user, "doit être administrateur") unless user&.admin? || user&.super_admin?
  end
end
