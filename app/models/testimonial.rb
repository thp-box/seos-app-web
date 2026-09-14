class Testimonial < ApplicationRecord
  include PublicText
  CONSENT_VERSION = "publication-2026-09-v1"
  belongs_to :user
  belongs_to :point_reward_claim, optional: true
  belongs_to :reviewed_by, class_name: "User", optional: true
  has_one_attached :video
  encrypts :decision
  validates :kind, inclusion: { in: %w[written video] }
  validates :status, inclusion: { in: %w[submitted published rejected removed] }
  validates :quote, :display_name_snapshot, :consent_version, :consented_at, presence: true
  validates :quote, :transcript, length: { maximum: 3000 }
  validates :display_name_snapshot, :public_location_snapshot, length: { maximum: 100 }
  validates :transcript, presence: true, if: -> { kind == "video" }
  validate -> { validate_public_text(:quote, :transcript, :display_name_snapshot, :public_location_snapshot) }
  def publicly_visible? = status == "published" && removed_at.nil? && consented_at.present? && user.active? && user.confirmed?
end
