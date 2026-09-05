class ChainService < ApplicationRecord
  belongs_to :help_chain
  belongs_to :provider, class_name: "User"
  belongs_to :beneficiary, class_name: "User", optional: true
  has_many :chain_rewards, dependent: :restrict_with_exception
  encrypts :description
  validates :description, presence: true, length: { maximum: 1500 }
  validates :status, inclusion: { in: %w[invited confirmed expired cancelled] }
  def self.digest(token) = Digest::SHA256.hexdigest(token.to_s)
  def available? = status == "invited" && invitation_expires_at > Time.current && help_chain.status == "active"
end
