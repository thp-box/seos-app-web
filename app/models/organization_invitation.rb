class OrganizationInvitation < ApplicationRecord
  belongs_to :organization
  belongs_to :invited_by, class_name: "User"
  belongs_to :accepted_by, class_name: "User", optional: true
  encrypts :email
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 254 }
  validates :role, inclusion: { in: %w[manager editor] }
  def available? = !accepted_at && !revoked_at && expires_at > Time.current && !organization.suspended?
end
