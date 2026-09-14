class TrustAlgorithmVersion < ApplicationRecord
  DEFAULT_CONFIGURATION = {
    "prior" => 2.0, "referral_weight" => 0.25, "half_life_days" => 548.0,
    "pair_cap" => 2.5, "author_cap" => 0.15, "category_cap" => 0.6,
    "exchange_threshold" => 3.0, "partner_threshold" => 3,
    "category_threshold" => 2.0, "category_partners" => 2,
    "dimensions" => { "reliability" => 0.30, "task_quality" => 0.25, "respect_safety" => 0.20, "communication" => 0.15, "punctuality" => 0.10 }
  }.freeze
  belongs_to :created_by, class_name: "User"
  belongs_to :approved_by, class_name: "User", optional: true
  validates :version, :explanation, presence: true
  validates :status, inclusion: { in: %w[draft simulated approved shadow active retired] }
  validate do
    errors.add(:configuration, "ne correspond pas à la formule V1 supportée") unless configuration == DEFAULT_CONFIGURATION
    if persisted? && (configuration_changed? || version_changed? || explanation_changed?)
      errors.add(:base, "Créez une nouvelle version pour modifier la formule ou son explication")
    end
  end
end
