class TopListingRequest < ApplicationRecord
  belongs_to :listing
  belongs_to :user
  belongs_to :reviewed_by, class_name: "User", optional: true
  encrypts :reason
  validates :status, inclusion: { in: %w[pending approved rejected withdrawn expired] }
  scope :effective, -> { where(status: "approved").where("starts_at <= ? AND ends_at > ?", Time.current, Time.current) }
  def eligible?
    rule = PointRuleVersion.current("engagement")
    listing.publicly_visible? && ListingPolicy.new(user, listing).update? && rule &&
      (Points::Rewards.level(user, rule) != "bronze" || PointRewardClaim.exists?(user: user, kind: "share", status: "approved", period_key: Time.current.strftime("%Y-%m")))
  end
end
