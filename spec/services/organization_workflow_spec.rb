require "rails_helper"

RSpec.describe OrganizationWorkflow do
  let(:owner) { create(:profile).user }
  let(:admin) { create(:user, :super_admin) }
  let(:organization) { organization_space(owner: owner) }

  it "crée un propriétaire, garde le contact privé, revoit et suspend la fiche" do
    record = described_class.create!(actor: owner, attributes: { name: "Les jardins", slug: "jardins", kind: "association" })
    expect(record).to be_pending
    expect(OrganizationPolicy.new(owner, record).workspace?).to be(true)
    expect { described_class.review!(organization: record, actor: owner, status: "verified", reason: "Non") }.to raise_error(Pundit::NotAuthorizedError)
    expect { described_class.review!(organization: record, actor: admin, status: "verified", reason: "Trop tôt") }.to raise_error(Exchanges::Invalid)
    described_class.update!(organization: record, actor: owner, attributes: { description: "Un jardin partagé", legal_name: "Structure privée", legal_email: "legal@example.test", registration_number: "W12345" })
    expect(record.ciphertext_for(:legal_name)).not_to include("Structure privée")
    described_class.review!(organization: record, actor: admin, status: "verified", reason: "Documents vérifiés")
    expect(record.publicly_visible?).to be(true)
    described_class.review!(organization: record, actor: admin, status: "suspended", reason: "Vérification complémentaire")
    expect(record.publicly_visible?).to be(false)
    expect(OrganizationPolicy.new(owner, record).workspace?).to be(false)
    described_class.review!(organization: record, actor: admin, status: "verified", reason: "Vérification terminée", kind: "collective")
    expect(record).to be_collective
    described_class.update!(organization: record, actor: owner, attributes: { legal_name: "Nouvelle identité légale" })
    expect(record).to be_pending
    expect(record.verified_at).to be_nil
  end

  it "lie l’invitation au compte, refuse expiration et réemploi, et respecte la hiérarchie" do
    invited = create(:user)
    manager = create(:organization_membership, organization: organization, role: :manager).user
    editor = create(:organization_membership, organization: organization, role: :editor).user
    expect { described_class.invite!(organization: organization, actor: editor, email: invited.email, role: "editor") }.to raise_error(Pundit::NotAuthorizedError)
    expect { described_class.invite!(organization: organization, actor: manager, email: invited.email, role: "manager") }.to raise_error(Pundit::NotAuthorizedError)
    token = described_class.invite!(organization: organization, actor: owner, email: invited.email.upcase, role: "manager")
    invitation = OrganizationInvitation.last
    expect(invitation.token_digest).to eq(Digest::SHA256.hexdigest(token))
    expect { described_class.accept!(invitation: invitation, actor: editor) }.to raise_error(Exchanges::Invalid)
    travel_to 8.days.from_now do
      expect { described_class.accept!(invitation: invitation, actor: invited) }.to raise_error(Exchanges::Invalid)
    end
    2.times { described_class.accept!(invitation: invitation, actor: invited) }
    expect(organization.organization_memberships.find_by!(user: invited)).to be_manager
    expect(organization.organization_memberships.where(user: invited).count).to eq(1)
    token = described_class.invite!(organization: organization, actor: manager, email: editor.email, role: "editor")
    described_class.accept!(invitation: OrganizationInvitation.find_by!(token_digest: Digest::SHA256.hexdigest(token)), actor: editor)
    expect(organization.organization_memberships.find_by!(user: editor)).to be_editor
    expect { described_class.update!(organization: organization, actor: editor, attributes: { legal_name: "Vol" }) }.to raise_error(Pundit::NotAuthorizedError)
    described_class.update!(organization: organization, actor: editor, attributes: { description: "Nouvelle présentation" })
    expect(organization.published_at).to be_nil
  end

  it "protège le dernier propriétaire en service et en base, puis récupère un accès exceptionnel" do
    membership = organization.organization_memberships.find_by!(user: owner)
    expect { described_class.membership!(membership: membership, actor: owner, role: "editor", status: "active") }.to raise_error(Exchanges::Invalid)
    expect { membership.update!(status: "revoked") }.to raise_error(ActiveRecord::StatementInvalid)
    replacement = create(:user)
    expect { described_class.recover_owner!(organization: organization, actor: owner, user: replacement, reason: "Non") }.to raise_error(Pundit::NotAuthorizedError)
    described_class.recover_owner!(organization: organization, actor: admin, user: replacement, reason: "Compte historique indisponible")
    described_class.membership!(membership: membership.reload, actor: replacement, role: "editor", status: "revoked")
    expect(membership).to be_revoked
    expect(AuditLog.where(action: "organization.owner.recovery").count).to eq(1)
  end

  it "révoque l’invitation lorsque son auteur perd son pouvoir et interdit les changements hors équipe" do
    invited = create(:user)
    described_class.invite!(organization: organization, actor: owner, email: invited.email, role: "manager")
    invitation = OrganizationInvitation.last
    described_class.recover_owner!(organization: organization, actor: admin, user: admin, reason: "Relais")
    membership = organization.organization_memberships.find_by!(user: owner)
    described_class.membership!(membership: membership, actor: admin, role: "manager", status: "active")
    expect { described_class.accept!(invitation: invitation, actor: invited) }.to raise_error(Exchanges::Invalid)
    expect { described_class.membership!(membership: membership, actor: invited, role: "owner", status: "active") }.to raise_error(Pundit::NotAuthorizedError)
    expect { described_class.membership!(membership: membership, actor: owner, role: "owner", status: "active") }.to raise_error(Pundit::NotAuthorizedError)
    staff = create(:user, :admin)
    grant_record = create(:admin_permission_grant, user: staff, permission: "organizations.manage")
    expect(grant_record).to be_valid
    expect { described_class.review!(organization: organization, actor: staff, status: "verified", kind: "company", reason: "Non") }.to raise_error(Pundit::NotAuthorizedError)
  end
end
