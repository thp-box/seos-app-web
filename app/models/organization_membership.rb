class OrganizationMembership < ApplicationRecord
  belongs_to :user
  belongs_to :organization
  enum :role, { owner: "owner", manager: "manager", editor: "editor" }, validate: true
  enum :status, { active: "active", revoked: "revoked" }, validate: true
  validates :user_id, uniqueness: { scope: :organization_id }
end
