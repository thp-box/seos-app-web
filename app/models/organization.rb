class Organization < ApplicationRecord
  include PublicText
  belongs_to :verified_by, class_name: "User", optional: true
  encrypts :legal_name, :registration_number, :legal_email
  has_one_attached :logo
  has_many :organization_invitations, dependent: :restrict_with_exception
  has_many :volunteer_missions, dependent: :restrict_with_exception
  has_many :partnerships, dependent: :restrict_with_exception
  validates :description, length: { maximum: 5000 }
  validates :public_location, :legal_name, :registration_number, length: { maximum: 150 }
  validates :legal_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate -> { validate_public_text(:name, :description, :public_location) }
  def publicly_visible? = verified? && published_at.present?
  enum :kind, { association: "association", company: "company", institution: "institution", collective: "collective" }, validate: true
  enum :status, { pending: "pending", verified: "verified", rejected: "rejected", suspended: "suspended" }, validate: true
  has_many :organization_memberships, dependent: :restrict_with_exception
  validates :name, presence: true, length: { maximum: 150 }
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  def to_param = slug
end
