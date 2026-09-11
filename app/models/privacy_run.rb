class PrivacyRun < ApplicationRecord
  belongs_to :retention_policy_version
  belongs_to :actor, class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true
  validates :status, inclusion: { in: %w[preview executed] }
  def readonly? = persisted? && status_in_database == "executed"
  encrypts :reason
  validates :reason, presence: true, length: { maximum: 500 }
end
