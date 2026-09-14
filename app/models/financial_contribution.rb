class FinancialContribution < ApplicationRecord
  after_update_commit :notify_status, if: -> { saved_change_to_status? && %w[paid failed expired partially_refunded refunded].include?(status) }
  def notify_status
    Notification.notify!(user: user, key: "support:#{id}:#{updated_at.to_f}:#{status}", title: "Le statut de votre soutien financier a été mis à jour.", category: "support")
  end
  belongs_to :user
  validates :request_key, format: { with: /\A[0-9a-f-]{36}\z/ }
  validates :amount_cents, numericality: { only_integer: true, in: 100..100_000 }
  validates :currency, inclusion: { in: [ "eur" ] }
  validates :status, inclusion: { in: %w[pending paid failed expired refund_pending partially_refunded refunded] }
end
