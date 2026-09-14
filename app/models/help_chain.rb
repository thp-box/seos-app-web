class HelpChain < ApplicationRecord
  belongs_to :creator, class_name: "User"
  belongs_to :chain_rule_version
  belongs_to :point_rule_version
  has_many :chain_services, dependent: :restrict_with_exception
  before_validation -> { self.slug ||= SecureRandom.hex(12) }
  validates :name, presence: true, length: { maximum: 100 }
  validates :status, inclusion: { in: %w[active closed disputed] }
  def participant?(user) = user && (creator_id == user.id || chain_services.where(provider: user).or(chain_services.where(beneficiary: user)).exists?)
  def next_provider = chain_services.where(status: "confirmed").order(:position).last&.beneficiary || creator
end
