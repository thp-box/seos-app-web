class ContactRequest < ApplicationRecord
  encrypts :email, :message
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, length: { maximum: 254 }
  validates :subject, presence: true, length: { maximum: 120 }
  validates :message, presence: true, length: { maximum: 5000 }
end
