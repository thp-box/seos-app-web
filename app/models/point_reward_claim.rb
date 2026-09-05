class PointRewardClaim < ApplicationRecord
  belongs_to :user
  belongs_to :point_rule_version
  belongs_to :reviewed_by, class_name: "User", optional: true
  belongs_to :point_operation, optional: true
  encrypts :evidence, :decision
  validates :evidence, presence: true, length: { maximum: 3000 }
  validates :kind, inclusion: { in: %w[written video share chain] }
  validates :status, inclusion: { in: %w[pending approved rejected] }
end
