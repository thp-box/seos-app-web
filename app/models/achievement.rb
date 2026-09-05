class Achievement < ApplicationRecord
  KEYS = %w[welcome listing responses referral cycle written video share chain].freeze
  validates :slug, format: { with: /\A[a-z0-9-]+\z/ }, uniqueness: true
  validates :name, :description, presence: true, length: { maximum: 1000 }
  validates :reward_key, inclusion: { in: KEYS }
  validates :recurrence, inclusion: { in: %w[once monthly cycle] }
  validates :event_name, inclusion: { in: KEYS + [ "manual" ] }
  validates :target_count, numericality: { only_integer: true, in: 1..100 }
  validate do
    errors.add(:base, "Les quêtes personnalisées demandent une preuve unique et une revue humaine") if !builtin? && (event_name != "manual" || target_count != 1 || recurrence == "cycle")
    errors.add(:base, "Le contrat d’une quête existante est figé") if persisted? && (changes.keys & %w[slug reward_key recurrence event_name target_count builtin]).any?
  end
end
