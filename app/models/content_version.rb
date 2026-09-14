class ContentVersion < ApplicationRecord
  include PublicText
  PAGE_SLUGS = %w[don echange points fonctionnement].freeze
  LEGAL_SLUGS = %w[mentions-legales confidentialite cgu cookies].freeze
  PRESETS = %w[wave_single wave_double soft_curve asymmetric_blob scallop diagonal_soft mist_fade].freeze
  belongs_to :author, class_name: "User"
  validates :kind, inclusion: { in: %w[page article legal] }
  validates :title, :body, :slug, :version, presence: true
  validates :slug, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :title, :summary, length: { maximum: 200 }
  validates :body, length: { maximum: 30_000 }
  validates :version, uniqueness: { scope: [ :kind, :slug ] }
  validate do
    errors.add(:slug, "n’est pas une page système") if kind == "page" && !PAGE_SLUGS.include?(slug)
    errors.add(:slug, "n’est pas un document légal") if kind == "legal" && !LEGAL_SLUGS.include?(slug)
    errors.add(:decorations, "contient un preset non autorisé") unless decorations.is_a?(Array) && decorations.size <= 8 && (decorations - PRESETS).empty?
  end
  scope :live, -> { where(archived_at: nil).where("published_at <= ?", Time.current) }
  def readonly? = persisted? && published_at_in_database.present?
  def self.current(kind, slug)
    live.where(kind: kind, slug: slug).order(version: :desc).first
  end
end
