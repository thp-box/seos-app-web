if Rails.env.development?
  admin = User.find_by!(email: "admin@seos.test")
  super_admin = User.find_by!(email: "superadmin@seos.test")
  %w[users.read reports.manage content.manage operations.read privacy.manage].each do |permission|
    AdminPermissionGrant.find_or_create_by!(user: admin, permission: permission, revoked_at: nil) do |grant|
      grant.granted_by = super_admin
      grant.granted_at = Time.current
      grant.expires_at = 30.days.from_now
      grant.reason = "Démonstration locale de la phase 7"
    end
  end
  organization = Organization.find_or_create_by!(slug: "partenaire-demo") do |record|
    record.name = "Partenaire de démonstration"
    record.kind = "company"
    record.status = "pending"
  end
  OrganizationMembership.find_or_create_by!(organization: organization, user: User.find_by!(email: "partenaire@seos.test")) do |membership|
    membership.role = "owner"
    membership.status = "active"
  end
end
