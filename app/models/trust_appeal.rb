class TrustAppeal < ApplicationRecord
  belongs_to :user
  belongs_to :trust_score_snapshot, optional: true
  belongs_to :referral, optional: true
  belongs_to :assigned_to, class_name: "User", optional: true
  encrypts :statement, :decision
  validates :statement, presence: true, length: { maximum: 3000 }
  validates :status, inclusion: { in: %w[open investigating accepted rejected] }
  validate do
    owner_id = trust_score_snapshot&.user_id || referral&.referred_user_id
    errors.add(:base, "La source du recours doit vous appartenir") if owner_id != user_id || (trust_score_snapshot.present? && referral.present?)
  end
end
