class TrustEvent < ApplicationRecord
  DIMENSIONS = %w[reliability task_quality respect_safety communication punctuality].freeze
  belongs_to :subject, class_name: "User"
  belongs_to :actor, class_name: "User", optional: true
  belongs_to :service_request, optional: true
  belongs_to :category, optional: true
  belongs_to :source, polymorphic: true
  has_many :trust_event_corrections
  validates :normalized_value, numericality: { in: 0..1 }
  validates :dimension, inclusion: { in: DIMENSIONS }
  validates :event_kind, inclusion: { in: %w[exchange review] }
  def readonly? = persisted?
end
