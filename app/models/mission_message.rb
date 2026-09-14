class MissionMessage < ApplicationRecord
  belongs_to :mission_application
  belongs_to :user
  encrypts :body
  validates :body, presence: true, length: { maximum: 3000 }
  validates :delivery_key, presence: true, length: { maximum: 100 }
  def readonly? = persisted?
end
