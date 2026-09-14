class LoginBlock < ApplicationRecord
  belongs_to :actor, class_name: "User"
  encrypts :reason
  validates :reason, presence: true, length: { maximum: 500 }
  validates :email_digest, presence: true
  validates :expires_at, comparison: { greater_than: -> { Time.current }, less_than: -> { 1.year.from_now } }
  def self.digest(email) = OpenSSL::HMAC.hexdigest("SHA256", Rails.application.key_generator.generate_key("login-blocks-v1"), email.to_s.strip.downcase)
  def self.blocked?(email) = where(email_digest: digest(email)).where("expires_at > ?", Time.current).exists?
end
