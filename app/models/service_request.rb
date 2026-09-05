class ServiceRequest < ApplicationRecord
  encrypts :agreement
  belongs_to :listing
  belongs_to :requester, class_name: "User"
  belongs_to :provider, class_name: "User"
  belongs_to :proposed_by, class_name: "User", optional: true
  has_many :messages, dependent: :restrict_with_exception
  has_many :request_events, dependent: :restrict_with_exception
  has_many :reviews, dependent: :restrict_with_exception
  enum :status, %w[pending accepted declined scheduled awaiting_confirmation completed cancelled disputed expired].index_with(&:itself), validate: true
  validates :expires_at, presence: true
  validate do
    errors.add(:requester, "ne peut pas répondre à sa propre annonce") if requester_id == provider_id
    errors.add(:provider, "doit être le propriétaire") if listing && provider_id != listing.user_id
  end
  scope :participating, ->(user) { where(requester_id: user.id).or(where(provider_id: user.id)) }
  def participant?(user) = user && [ requester_id, provider_id ].include?(user.id)
  def other(user) = user.id == requester_id ? provider : requester
  def side(user) = user.id == requester_id ? "requester" : "provider"
  def blocked? = UserBlock.between?(requester_id, provider_id)
  def agreed? = requester_agreed_at.present? && provider_agreed_at.present?
  def current_status = pending? && expires_at <= Time.current ? "expired" : status
  def shared_contact_for(user)
    return {} unless participant?(user) && agreed? && %w[scheduled awaiting_confirmation].include?(status) && !blocked?
    partner = other(user)
    return {} unless public_send("#{side(partner)}_shared_at") && partner.profile&.phone_sharing_policy == "per_exchange"
    { phone: partner.profile.phone, address: partner.profile.address_line }.compact_blank
  end
end
