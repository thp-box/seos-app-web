class ReviewCriterion < ApplicationRecord
  self.table_name = "review_criteria"
  belongs_to :category, optional: true
  validates :key, :label, presence: true
  scope :applicable, ->(request, user) { where(active: true, category_id: [ nil, request.listing.category_id ], evaluator_role: [ "both", request.side(user) ]) }
end
