class ReferralExemption < ApplicationRecord
  belongs_to :user
  belongs_to :granted_by, class_name: "User"
  validates :reason, presence: true, length: { maximum: 500 }
  validates :expires_at, presence: true
end
