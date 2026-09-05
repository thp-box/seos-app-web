class RequestEvent < ApplicationRecord
  belongs_to :service_request
  belongs_to :actor, class_name: "User"
  validates :kind, presence: true
  encrypts :details
  def readonly? = persisted?
end
