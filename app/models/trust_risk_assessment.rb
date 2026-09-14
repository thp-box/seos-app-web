class TrustRiskAssessment < ApplicationRecord
  SIGNALS = %w[exchange_burst repeated_pair referral_burst referral_cycle].freeze
  belongs_to :user
  belongs_to :reviewed_by, class_name: "User", optional: true
  encrypts :decision
  validates :signal, inclusion: { in: SIGNALS }
  validates :status, inclusion: { in: %w[open dismissed reviewed expired] }
end
