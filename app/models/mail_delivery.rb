class MailDelivery < ApplicationRecord
  validates :message_id, presence: true, uniqueness: true
  validates :status, inclusion: { in: %w[uncertain sent] }
end
