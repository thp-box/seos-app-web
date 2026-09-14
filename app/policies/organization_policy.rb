class OrganizationPolicy < ApplicationPolicy
  def show?
    !!(user&.active? && user.confirmed? && record.verified? && membership)
  end

  def team?
    show? && (membership.owner? || membership.manager?)
  end

  def workspace? = !!(user&.active? && user.confirmed? && !record.suspended? && membership)
  def manage_team? = workspace? && (membership.owner? || membership.manager?)
  def owner? = workspace? && membership.owner?
  def edit_content? = workspace? && record.verified?

  private

  def membership
    @membership ||= record.organization_memberships.active.find_by(user: user)
  end
end
