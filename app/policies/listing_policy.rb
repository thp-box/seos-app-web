class ListingPolicy < ApplicationPolicy
  def update?
    return false unless user&.active_for_authentication?
    return record.user_id == user.id unless record.organization
    record.organization.association? && record.organization.verified? && record.organization.organization_memberships.active.exists?(user: user)
  end
end
