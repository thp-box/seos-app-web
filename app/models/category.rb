class Category < ApplicationRecord
  belongs_to :parent, class_name: "Category", optional: true
  has_many :children, class_name: "Category", foreign_key: :parent_id, inverse_of: :parent
  has_many :listings, dependent: :restrict_with_exception
  validates :name, :slug, presence: true, length: { maximum: 100 }
  validates :slug, uniqueness: true, format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/ }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validate :acyclic_parent
  scope :available, -> { where(active: true, deleted_at: nil).order(:position, :name) }
  scope :kept, -> { where(deleted_at: nil) }
  scope :roots, -> { kept.where(parent_id: nil) }
  def lineage
    result, node = [], self
    while node && !result.include?(node)
      result << node
      node = node.parent
    end
    result
  end
  def publishable? = lineage.all? { |category| category.active? && category.deleted_at.nil? }
  private
  def acyclic_parent
    errors.add(:parent, "ne peut pas former de cycle") if parent && parent.lineage.include?(self)
  end
end
