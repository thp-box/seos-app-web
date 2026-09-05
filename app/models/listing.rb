class Listing < ApplicationRecord
  after_commit -> { PointRewardsJob.perform_later(user_id) }, if: :published?
  include PublicText
  belongs_to :user
  belongs_to :organization, optional: true
  belongs_to :category, optional: true
  has_many_attached :photos
  has_many :service_requests, dependent: :restrict_with_exception
  has_many :top_listing_requests, dependent: :restrict_with_exception
  has_many :comments, dependent: :restrict_with_exception
  encrypts :address_line
  enum :status, %w[draft pending_review published paused closed removed].index_with(&:itself), validate: true
  enum :intent, %w[offer request].index_with(&:itself), prefix: true, validate: true
  enum :exchange_mode, %w[gift barter points].index_with(&:itself), prefix: true, validate: true
  enum :service_location_mode, %w[in_person remote hybrid].index_with(&:itself), prefix: true, validate: true
  validates :slug, presence: true, uniqueness: true
  validates :title, length: { maximum: 120 }
  validates :description, length: { maximum: 5000 }
  validates :availability, length: { maximum: 1000 }
  validates :city, length: { maximum: 100 }
  validates :priority, inclusion: { in: %w[standard urgent] }
  validates :estimated_points, numericality: { only_integer: true, greater_than: 0, less_than: 1_000_000 }, allow_nil: true
  before_validation do
    self.urgent_until = priority == "urgent" ? CommunityPolicyVersion.current.urgent_days.days.from_now : nil if will_save_change_to_priority?
    self.slug ||= SecureRandom.hex(10)
    self.estimated_points = nil unless exchange_mode_points?
    self.latitude = self.longitude = nil if service_location_mode_remote? || will_save_change_to_city?
  end
  validate -> { validate_public_text(:title, :description, :availability, :city) }
  validates :title, :description, :category, presence: true, on: [ :publication, :moderated_publication ]
  validate :publication_rules, on: [ :publication, :moderated_publication ]
  scope :public_candidates, -> { published.joins(:user, :category).where(users: { status: :active }, categories: { active: true }).where.not(users: { confirmed_at: nil }) }
  def publicly_visible?
    published? && !moderation_hold? && user.active_for_authentication? && user.profile&.published? && category&.publishable? &&
      (!organization || organization.verified?) && !restricted?
  end
  def restricted? = CategoryRestriction.effective.any? { |restriction| restriction.matches?(self) }
  def public_coordinates
    return unless publicly_visible? && !service_location_mode_remote? && city.present? && latitude && longitude
    [ latitude.round(2), longitude.round(2) ]
  end
  def urgent? = priority == "urgent" && urgent_until.present? && urgent_until > Time.current
  def top_placement = top_listing_requests.effective.order(:position).detect(&:eligible?)
  def map_eligible? = FeatureFlag.map_enabled? && public_coordinates.present?
  def location_label = service_location_mode_remote? ? "À distance — France" : city
  def to_param = slug
  private
  def publication_rules
    errors.add(:base, "Complétez et publiez votre profil avant votre annonce") unless user.profile&.published?
    errors.add(:category, "est indisponible") unless category&.publishable?
    errors.add(:base, "Cette annonce nécessite une revue de modération") if restricted? || (category&.sensitive? && validation_context != :moderated_publication)
    errors.add(:city, "doit être renseignée") unless service_location_mode_remote? || city.present?
    errors.add(:estimated_points, "doit être renseigné en mode points") if exchange_mode_points? && estimated_points.nil?
    errors.add(:organization, "doit être une association vérifiée") if organization && !(organization.association? && organization.verified?)
  end
end
