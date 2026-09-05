class PointEntry < ApplicationRecord
  belongs_to :point_account
  belongs_to :point_operation
  validates :amount, numericality: { only_integer: true, other_than: 0, in: -999_999..999_999 }
  def readonly? = persisted?
end
