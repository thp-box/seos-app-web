class OrganizationWorkflow
  def self.create!(actor:, attributes:)
    Chains.active!(actor)
    Organization.transaction do
      organization = Organization.create!(attributes.merge(status: "pending"))
      organization.organization_memberships.create!(user: actor, role: "owner")
      AuditLog.create!(actor: actor, target: organization, action: "organization.request", reason: "Demande de création d’une organisation")
      organization
    end
  end

  def self.update!(organization:, actor:, attributes:, logo: nil)
    policy = OrganizationPolicy.new(actor, organization)
    raise Pundit::NotAuthorizedError unless policy.workspace?
    raise Pundit::NotAuthorizedError if attributes.keys.map(&:to_s).intersect?(%w[legal_name legal_email registration_number]) && !policy.owner?
    organization.with_lock do
      organization.assign_attributes(attributes)
      organization.assign_attributes(status: "pending", verified_at: nil, verified_by: nil) if (organization.changes.keys & %w[legal_name legal_email registration_number]).any?
      organization.update!(published_at: nil)
      SafeImage.attach!(organization.logo, logo) if logo.present?
      AuditLog.create!(actor: actor, target: organization, action: "organization.edited", reason: "Profil modifié, publication à revoir")
    end
  end

  def self.invite!(organization:, actor:, email:, role:)
    policy = OrganizationPolicy.new(actor, organization)
    raise Pundit::NotAuthorizedError unless policy.manage_team? && (role == "editor" || (policy.owner? && role == "manager"))
    token = SecureRandom.urlsafe_base64(24)
    organization.with_lock do
      invitation = organization.organization_invitations.create!(invited_by: actor, email: email.to_s.strip.downcase, role: role,
        token_digest: Digest::SHA256.hexdigest(token), expires_at: 7.days.from_now)
      AuditLog.create!(actor: actor, target: invitation, action: "organization.invite", reason: "Invitation privée dans l’équipe")
    end
    token
  end

  def self.accept!(invitation:, actor:)
    Chains.active!(actor)
    invitation.organization.with_lock do
      invitation.reload
      return if invitation.accepted_by_id == actor.id
      raise Exchanges::Invalid, "Invitation indisponible, expirée ou destinée à un autre compte." unless invitation.available? && invitation.email == actor.email.downcase
      inviter_policy = OrganizationPolicy.new(invitation.invited_by, invitation.organization)
      raise Exchanges::Invalid, "L’invitation a été révoquée par le changement de droits de son auteur." unless inviter_policy.manage_team? && (invitation.role == "editor" || inviter_policy.owner?)
      membership = invitation.organization.organization_memberships.find_or_initialize_by(user: actor)
      membership.assign_attributes(role: invitation.role, status: "active") unless membership.persisted? && membership.active?
      membership.save!
      invitation.update!(accepted_by: actor, accepted_at: Time.current)
      AuditLog.create!(actor: actor, target: invitation, action: "organization.join", reason: "Invitation acceptée par le compte destinataire")
    end
  end

  def self.membership!(membership:, actor:, role:, status:)
    organization = membership.organization
    policy = OrganizationPolicy.new(actor, organization)
    raise Pundit::NotAuthorizedError unless policy.manage_team?
    raise Pundit::NotAuthorizedError unless policy.owner? || (membership.editor? && role == "editor")
    raise Exchanges::Invalid, "Le compte doit être actif et confirmé." if status == "active" && !membership.user.active_for_authentication?
    organization.with_lock do
      membership.reload
      if membership.owner? && membership.active? && (role != "owner" || status != "active") && !organization.organization_memberships.active.where(role: "owner").where.not(id: membership.id).exists?
        raise Exchanges::Invalid, "Nommez un autre propriétaire avant de retirer le dernier."
      end
      membership.update!(role: role, status: status)
      AuditLog.create!(actor: actor, target: membership, action: "organization.team", reason: "Modification des droits de l’équipe", metadata: { to: "#{role}/#{status}" })
    end
  end

  def self.recover_owner!(organization:, actor:, user:, reason:)
    raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.permission?("organizations.manage")
    Chains.active!(user)
    organization.with_lock do
      membership = organization.organization_memberships.find_or_initialize_by(user: user)
      membership.update!(role: "owner", status: "active")
      AuditLog.create!(actor: actor, target: organization, action: "organization.owner.recovery", reason: reason, metadata: { to: user.id })
    end
  end

  def self.review!(organization:, actor:, status:, reason:, kind: nil)
    raise Pundit::NotAuthorizedError unless actor.permission?("organizations.manage")
    raise Pundit::NotAuthorizedError if kind.present? && !actor.super_admin?
    organization.with_lock do
      if status == "verified"
        raise Exchanges::Invalid, "Complétez la présentation et l’identité légale avant vérification." unless organization.description.present? && organization.legal_name.present? && organization.legal_email.present? && organization.registration_number.present?
        raise Exchanges::Invalid, "L’organisation doit avoir un propriétaire actif." unless organization.organization_memberships.active.where(role: "owner").joins(:user).where(users: { status: "active" }).where.not(users: { confirmed_at: nil }).exists?
      end
      organization.update!(status: status, kind: kind.presence || organization.kind, verified_at: status == "verified" ? Time.current : organization.verified_at,
        verified_by: actor, published_at: status == "verified" ? Time.current : nil)
      AuditLog.create!(actor: actor, target: organization, action: "organization.#{status}", reason: reason)
    end
  end
end
