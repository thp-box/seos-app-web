class TrustEventCorrection < ApplicationRecord
  belongs_to :trust_event
  belongs_to :actor, class_name: "User"
  encrypts :reason
  validates :reason, presence: true, length: { maximum: 500 }
  validates :excluded, inclusion: { in: [ true, false ] }
  def readonly? = persisted?
end
