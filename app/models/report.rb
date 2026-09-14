class Report < ApplicationRecord
  TARGETS = %w[Listing Profile Message Comment Review ServiceRequest].freeze
  belongs_to :reporter, class_name: "User"
  belongs_to :reportable, polymorphic: true
  belongs_to :assigned_to, class_name: "User", optional: true
  encrypts :details
  validates :reason, presence: true, length: { maximum: 200 }
  validates :details, :resolution, length: { maximum: 3000 }
  validates :reportable_type, inclusion: { in: TARGETS }
  validates :status, inclusion: { in: %w[open investigating resolved] }
  before_validation -> { self.due_at ||= 72.hours.from_now }
end
