class CommunityPolicyVersion < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  validates :urgent_days, numericality: { only_integer: true, in: 1..30 }
  validates :top_max_days, numericality: { only_integer: true, in: 1..90 }
  def self.current = order(id: :desc).first || new
  def readonly? = persisted?
end
