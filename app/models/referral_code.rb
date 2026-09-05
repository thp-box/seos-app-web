class ReferralCode < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_one :referral
  scope :available, -> { where(claimed_at: nil).where("expires_at > ?", Time.current) }
  validates :code_digest, :expires_at, presence: true
  def self.digest(code) = Digest::SHA256.hexdigest(code.to_s.strip)
end
