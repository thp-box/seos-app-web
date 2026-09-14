class AuditLog < ApplicationRecord
  belongs_to :actor, class_name: "User"
  belongs_to :target, polymorphic: true
  validates :action, :reason, presence: true
  validates :reason, length: { maximum: 500 }
  validate :safe_metadata

  def readonly? = persisted?

  private

  def safe_metadata
    unless metadata.is_a?(Hash) && (metadata.keys - %w[from to permission grant_id]).empty? && metadata.values.all? { |value| value.is_a?(String) || value.is_a?(Integer) }
      errors.add(:metadata, "contient des champs non autorisés")
    end
  end
end
