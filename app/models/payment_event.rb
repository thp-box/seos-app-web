class PaymentEvent < ApplicationRecord
  belongs_to :financial_contribution, optional: true
  def readonly? = persisted?
end
