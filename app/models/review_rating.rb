class ReviewRating < ApplicationRecord
  belongs_to :review
  belongs_to :review_criterion
  validates :rating, inclusion: { in: 1..5 }, unless: :not_applicable?
  validates :rating, absence: true, if: :not_applicable?
  validates :label_snapshot, presence: true
end
