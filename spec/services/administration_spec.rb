require "rails_helper"
RSpec.describe "Mutations administratives", :"F-004", :"F-006", type: :service do
  let(:actor) { create(:user, :super_admin) }
  let(:user) { create(:user) }

  it "change le rôle une seule fois en révoquant sessions et permissions" do
    session, = LoginSession.issue!(user: user, user_agent: "Firefox")
    2.times { Administration::ChangeRole.call(actor: actor, user: user, role: "admin", reason: "Support") }
    expect(AuditLog.count).to eq(1)
    expect(session.reload.revoked_at).to be_present
    grant = create(:admin_permission_grant, user: user)
    Administration::ChangeRole.call(actor: actor, user: user, role: "member", reason: "Fin")
    expect(grant.reload.revoked_at).to be_present
  end

  it "refuse un acteur sans droit, une cible protégée et un motif vide" do
    expect { Administration::ChangeRole.call(actor: user, user: actor, role: "admin", reason: "Support") }.to raise_error(Pundit::NotAuthorizedError)
    expect { Administration::ChangeRole.call(actor: actor, user: actor, role: "admin", reason: "Support") }.to raise_error(ArgumentError)
    expect { Administration::ChangeRole.call(actor: actor, user: user, role: "admin", reason: "") }.to raise_error(ArgumentError)
  end

  it "crée un droit une seule fois et conserve les anciennes attributions" do
    admin = create(:user, :admin)
    arguments = { actor: actor, user: admin, permission: "users.read", reason: "Support", expires_at: 1.day.from_now }
    2.times { Administration::GrantPermission.call(**arguments) }
    expect(AdminPermissionGrant.count).to eq(1)
    previous = AdminPermissionGrant.last
    previous.update!(expires_at: 1.second.ago)
    Administration::GrantPermission.call(**arguments)
    expect(previous.reload.revoked_at).to be_present
    expect(AdminPermissionGrant.count).to eq(2)
    current = AdminPermissionGrant.last
    2.times { Administration::RevokePermission.call(actor: actor, grant: current, reason: "Fin") }
    expect(AuditLog.where(action: "permission.revoked").count).to eq(1)
  end

  it "valide rôle cible, permission, expiration et auteur" do
    expect { Administration::GrantPermission.call(actor: user, user: actor, permission: "users.read", reason: "Support", expires_at: 1.day.from_now) }.to raise_error(Pundit::NotAuthorizedError)
    expect { Administration::GrantPermission.call(actor: actor, user: user, permission: "users.read", reason: "Support", expires_at: 1.day.from_now) }.to raise_error(ArgumentError)
    admin = create(:user, :admin)
    expect { Administration::GrantPermission.call(actor: actor, user: admin, permission: "users.read", reason: "Support", expires_at: 1.day.ago) }.to raise_error(ArgumentError)
    expect { Administration::GrantPermission.call(actor: actor, user: admin, permission: "studio.theme.manage", reason: "Support", expires_at: 1.day.from_now) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(AuditLog.count).to eq(0)
    grant = create(:admin_permission_grant, user: admin)
    expect { Administration::RevokePermission.call(actor: user, grant: grant, reason: "Fin") }.to raise_error(Pundit::NotAuthorizedError)
    expect { Administration::RevokePermission.call(actor: actor, grant: grant, reason: "") }.to raise_error(ArgumentError)
    expect(grant.reload.revoked_at).to be_nil
  end

  it "annule la mutation si l'audit ne peut pas être créé" do
    allow(AuditLog).to receive(:create!).and_raise(ActiveRecord::RecordInvalid)
    expect { Administration::ChangeRole.call(actor: actor, user: user, role: "admin", reason: "Support") }.to raise_error(ActiveRecord::RecordInvalid)
    expect(user.reload).to be_member
  end
end
