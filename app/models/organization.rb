class Organization < ApplicationRecord
  enum :kind, { association: "association", company: "company", institution: "institution", collective: "collective" }, validate: true
  enum :status, { pending: "pending", verified: "verified", rejected: "rejected", suspended: "suspended" }, validate: true
  has_many :organization_memberships, dependent: :restrict_with_exception
  validates :name, presence: true, length: { maximum: 150 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  def to_param = slug
end
