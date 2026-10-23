class PartnerEntry < ApplicationRecord
  belongs_to :partnership_page
  has_one_attached :logo

  validates :title, presence: true, length: { maximum: 150 }
  validates :description, length: { maximum: 600 }
  validates :website_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[https]) }
  validates :position, numericality: { only_integer: true, in: 0..10_000 }
  validate :acceptable_logo

  private

  def acceptable_logo
    return unless logo.attached?
    errors.add(:logo, "doit être au format JPEG, PNG ou WebP") unless logo.blob.content_type.in?(%w[image/jpeg image/png image/webp])
    errors.add(:logo, "ne doit pas dépasser 5 Mo") if logo.blob.byte_size > 5.megabytes
  end
end
