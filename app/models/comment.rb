class Comment < ApplicationRecord
  include PublicText
  belongs_to :user
  belongs_to :listing
  validates :body, presence: true, length: { maximum: 1500 }
  validate -> { validate_public_text(:body) }
  scope :visible, -> { where(removed_at: nil).joins(:user).where(users: { status: :active }) }
end
