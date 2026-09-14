class CategoryRestriction < ApplicationRecord
  belongs_to :category, optional: true
  belongs_to :created_by, class_name: "User"
  validates :reason, :starts_at, presence: true
  validates :reason, :term, length: { maximum: 200 }
  validates :existing_action, inclusion: { in: %w[review pause] }
  validate do
    errors.add(:base, "Choisissez une catégorie ou un terme") unless category || term.present?
    errors.add(:ends_at, "doit suivre le début") if ends_at && starts_at && ends_at <= starts_at
  end
  scope :effective, -> { where(active: true).where("starts_at <= ? AND (ends_at IS NULL OR ends_at > ?)", Time.current, Time.current) }
  def matches?(listing)
    (category_id.nil? || listing.category&.lineage&.any? { |item| item.id == category_id }) &&
      (term.blank? || "#{listing.title} #{listing.description}".downcase.include?(term.downcase))
  end
end
