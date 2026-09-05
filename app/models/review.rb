class Review < ApplicationRecord
  after_commit -> { TrustRecalculationJob.perform_later(reviewee_id) }
  include PublicText
  belongs_to :service_request
  belongs_to :author, class_name: "User"
  belongs_to :reviewee, class_name: "User"
  has_many :review_ratings, dependent: :restrict_with_exception
  validates :author_id, uniqueness: { scope: :service_request_id }
  validates :completion_answer, inclusion: { in: %w[yes partially no] }
  validates :would_reengage, inclusion: { in: [ true, false ] }
  validates :factual_body, :response, length: { maximum: 2000 }
  validate -> { validate_public_text(:factual_body, :response) }
  scope :revealed, -> { where("reveal_at <= ?", Time.current).where(invalidated_at: nil) }
  def revealed? = reveal_at <= Time.current && invalidated_at.nil?
end
