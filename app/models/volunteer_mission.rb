class VolunteerMission < ApplicationRecord
  include PublicText
  FIELDS = %i[title description country_code region public_location private_address starts_on ends_on minimum_stay_days help_hours_per_day days_off_per_week languages daily_contribution_cents daily_contribution_euros volunteer_capacity accommodation meals].freeze
  belongs_to :organization
  belongs_to :published_by, class_name: "User", optional: true
  has_many_attached :photos
  has_many :mission_applications, dependent: :restrict_with_exception
  encrypts :private_address
  before_validation { self.slug ||= SecureRandom.hex(10) }
  validates :title, presence: true, length: { maximum: 150 }
  validates :description, :accommodation, :meals, length: { maximum: 5000 }
  validates :region, :public_location, :languages, length: { maximum: 150 }
  validates :private_address, length: { maximum: 500 }
  validates :country_code, format: { with: /\A[A-Z]{2}\z/ }, allow_blank: true
  validates :status, inclusion: { in: %w[draft pending_review published paused archived] }
  validates :daily_contribution_cents, numericality: { only_integer: true, in: 0..1500 }
  validates :volunteer_capacity, numericality: { only_integer: true, in: 1..100 }
  validates :minimum_stay_days, numericality: { only_integer: true, greater_than: 0 }
  validates :help_hours_per_day, numericality: { only_integer: true, in: 1..8 }
  validates :days_off_per_week, numericality: { only_integer: true, in: 1..6 }
  validates :description, :country_code, :public_location, :starts_on, :ends_on, :languages, :accommodation, :meals, presence: true, on: :publication
  validate -> { validate_public_text(:title, :description, :region, :public_location, :accommodation, :meals) }
  validate do
    errors.add(:ends_on, "doit suivre le début et permettre le séjour minimal") if starts_on && ends_on && (ends_on < starts_on || (ends_on - starts_on).to_i + 1 < minimum_stay_days.to_i)
    errors.add(:ends_on, "ne peut pas être passée") if validation_context == :publication && ends_on && ends_on < Date.current
    errors.add(:organization, "doit être une association vérifiée") if validation_context == :publication && !(organization&.association? && organization.verified?)
  end
  def daily_contribution_euros = daily_contribution_cents && format("%.2f", daily_contribution_cents / 100.0)
  def daily_contribution_euros=(value)
    text = value.to_s.tr(",", ".")
    self.daily_contribution_cents = text.match?(/\A\d{1,4}(?:\.\d{1,2})?\z/) ? (BigDecimal(text) * 100).to_i : nil
  end
  def publicly_visible? = FeatureFlag.voyage_enabled? && status == "published" && organization.association? && organization.verified? && ends_on && ends_on >= Date.current
  def to_param = slug
end
