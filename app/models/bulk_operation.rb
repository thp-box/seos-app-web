class BulkOperation < ApplicationRecord
  belongs_to :actor, class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true
  def readonly? = persisted? && executed_at_in_database.present?
  encrypts :reason
  validates :reason, presence: true, length: { maximum: 500 }
  validates :expires_at, presence: true
end
