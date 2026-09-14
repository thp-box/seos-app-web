class ChainRuleVersion < ApplicationRecord
  FIELDS = %w[length_mode max_links reward_scope rewarded_previous_links points_per_validation max_points_per_link max_points_per_member effective_at].freeze
  belongs_to :created_by, class_name: "User", optional: true
  validates :name, :effective_at, presence: true
  validates :status, inclusion: { in: %w[draft simulated published] }
  validates :length_mode, inclusion: { in: %w[limited unlimited] }
  validates :reward_scope, inclusion: { in: %w[provider_only last_n_eligible all_eligible] }
  validates :rewarded_previous_links, numericality: { only_integer: true, in: 1..10 }
  validates :points_per_validation, :max_points_per_link, :max_points_per_member, numericality: { only_integer: true, in: 1..1000 }
  validates :max_links, numericality: { only_integer: true, in: 1..1000 }, if: -> { length_mode == "limited" }
  validate do
    errors.add(:max_links, "doit être vide en mode illimité") if length_mode == "unlimited" && max_links
    errors.add(:reward_scope, "tous les membres exige une longueur bornée") if reward_scope == "all_eligible" && length_mode == "unlimited"
  end
  def readonly? = persisted? && status_in_database == "published"
  def fingerprint = Digest::SHA256.hexdigest(attributes.slice(*FIELDS).to_json)
  def self.current = where(status: "published").where("effective_at <= ?", Time.current).order(effective_at: :desc).first
end
