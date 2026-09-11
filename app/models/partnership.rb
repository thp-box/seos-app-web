class Partnership < ApplicationRecord
  include PublicText
  KINDS = %w[institutional operational technical support].freeze
  FIELDS = %i[public_title public_description cta_label cta_url starts_on ends_on].freeze
  belongs_to :organization
  belongs_to :approved_by, class_name: "User", optional: true
  has_one_attached :logo
  before_validation { self.slug ||= SecureRandom.hex(10) }
  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: %w[draft pending_review published archived] }
  validates :public_title, presence: true, length: { maximum: 150 }
  validates :public_description, length: { maximum: 5000 }
  validates :cta_label, length: { maximum: 80 }
  validates :position, numericality: { only_integer: true, in: 0..1000 }
  validates :public_description, :starts_on, :ends_on, presence: true, on: :publication
  validate -> { validate_public_text(:public_title, :public_description) }
  validate do
    errors.add(:ends_on, "doit suivre le début") if starts_on && ends_on && ends_on < starts_on
    errors.add(:cta_url, "doit être une adresse HTTPS sans identifiant") if cta_url.present? && !safe_link?
    errors.add(:cta_label, "est requis avec le lien") if cta_url.present? && cta_label.blank?
    errors.add(:organization, "doit être vérifiée") if validation_context == :publication && !organization&.verified?
    errors.add(:ends_on, "ne peut pas être passée") if validation_context == :publication && ends_on && ends_on < Date.current
  end
  def safe_link?
    uri = URI.parse(cta_url)
    uri.is_a?(URI::HTTPS) && uri.host.present? && !uri.userinfo
  rescue URI::InvalidURIError
    false
  end
  def publicly_visible? = FeatureFlag.partnerships_enabled? && status == "published" && organization.verified? && starts_on && ends_on && (starts_on..ends_on).cover?(Date.current)
  def to_param = slug
end
