class AdministrationPolicy < ApplicationPolicy
  def show? = !!user&.administrative?
  def super_admin? = show? && user.super_admin?
  def users? = !!user&.permission?("users.read")
  def audit? = !!user&.permission?("audit.read")
end
