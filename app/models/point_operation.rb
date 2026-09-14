class PointOperation < ApplicationRecord
  KINDS = %w[welcome_reward service_transfer achievement_reward chain_reward referral_reward cycle_reward admin_adjustment reversal].freeze
  belongs_to :initiator, class_name: "User", optional: true
  belongs_to :source, polymorphic: true
  belongs_to :point_rule_version, optional: true
  belongs_to :reversed_operation, class_name: "PointOperation", optional: true
  has_many :point_entries, dependent: :restrict_with_exception
  has_one :reversal, class_name: "PointOperation", foreign_key: :reversed_operation_id
  encrypts :reason
  validates :kind, inclusion: { in: KINDS }
  validates :reason, presence: true, length: { maximum: 500 }
  validates :reversed_operation, presence: true, if: -> { kind == "reversal" }
  scope :committed, -> { where(status: "committed") }
  def readonly? = persisted? && status_in_database == "committed"
end
