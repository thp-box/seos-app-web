class Profile < ApplicationRecord
  include PublicText
  belongs_to :user
  has_one_attached :avatar
  encrypts :phone, :address_line
  enum :status, %w[draft published restricted anonymized].index_with(&:itself), validate: true
  validates :display_name, presence: true, length: { maximum: 80 }
  validates :bio, length: { maximum: 2000 }
  validates :public_city, :skills, :languages, length: { maximum: 200 }
  validates :phone_sharing_policy, inclusion: { in: %w[per_exchange nobody] }
  validates :public_slug, presence: true, uniqueness: true
  before_validation -> { self.public_slug ||= SecureRandom.hex(10) }
  validate -> { validate_public_text(:display_name, :bio, :public_city, :skills, :languages) }
  scope :visible, -> { published.joins(:user).where(users: { status: :active }).where.not(users: { confirmed_at: nil }) }
  def to_param = public_slug
end
