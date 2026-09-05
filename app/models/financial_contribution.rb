class FinancialContribution < ApplicationRecord
  belongs_to :user
  validates :request_key, format: { with: /\A[0-9a-f-]{36}\z/ }
  validates :amount_cents, numericality: { only_integer: true, in: 100..100_000 }
  validates :currency, inclusion: { in: [ "eur" ] }
  validates :status, inclusion: { in: %w[pending paid failed expired refund_pending partially_refunded refunded] }
end
