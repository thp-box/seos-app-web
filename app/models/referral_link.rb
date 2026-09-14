class ReferralLink < ApplicationRecord
  belongs_to :owner, class_name: "User"
  has_many :referrals, dependent: :restrict_with_exception
  has_secure_token :token, length: 32
  validates :owner_id, uniqueness: true
end
