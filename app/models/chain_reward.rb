class ChainReward < ApplicationRecord
  belongs_to :chain_service
  belongs_to :recipient, class_name: "User"
  belongs_to :chain_rule_version
  belongs_to :point_operation, optional: true
  def readonly? = persisted?
end
