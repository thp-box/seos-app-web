class OrganizationPolicy < ApplicationPolicy
  def show?
    !!(user&.active? && user.confirmed? && record.verified? && membership)
  end

  def team?
    show? && (membership.owner? || membership.manager?)
  end

  private

  def membership
    @membership ||= record.organization_memberships.active.find_by(user: user)
  end
end
