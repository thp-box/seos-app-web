class Referral < ApplicationRecord
  belongs_to :referral_code
  belongs_to :referrer, class_name: "User"
  belongs_to :referred_user, class_name: "User"
  encrypts :invalidation_reason
  scope :valid_support, -> { where(status: %w[provisional confirmed]) }
  validates :position, inclusion: { in: 1..10 }
  validates :status, inclusion: { in: %w[provisional confirmed objected invalidated] }
  after_commit -> { TrustRecalculationJob.perform_later(referred_user_id) }
  after_commit -> { PointRewardsJob.perform_later(referrer_id) }, if: :qualified_at?
end
