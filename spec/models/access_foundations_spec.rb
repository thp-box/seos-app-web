require "rails_helper"
RSpec.describe "Contraintes d'accès et audit", :"F-004", :"F-006", type: :model do
  it "interdit modification et suppression d'un audit en Ruby et en SQL" do
    user = create(:user, :super_admin)
    audit = AuditLog.create!(actor: user, target: user, action: "user.role_changed", reason: "Initialisation")
    expect { audit.update!(reason: "Modifié") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { AuditLog.where(id: audit.id).update_all(reason: "Modifié") }.to raise_error(ActiveRecord::StatementInvalid)
    expect { AuditLog.where(id: audit.id).delete_all }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "refuse les métadonnées privées et les permissions sur un membre" do
    user = create(:user)
    expect(AuditLog.new(actor: user, target: user, action: "test", reason: "Test", metadata: { email: user.email })).not_to be_valid
    expect(AuditLog.new(actor: user, target: user, action: "test", reason: "Test", metadata: [])).not_to be_valid
    expect(build(:admin_permission_grant, user: user)).not_to be_valid
  end

  it "stocke seulement le condensat du jeton, borne la session et résume le navigateur" do
    user = create(:user)
    session, token = LoginSession.issue!(user: user, user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/151.0.0.0 Safari/537.36")
    expect(session.token_digest).not_to eq(token)
    expect(session.token_digest).to eq(Digest::SHA256.hexdigest(token))
    expect(session.user_agent_summary).not_to include("Mozilla/5.0")
    expect(session).to be_recently_authenticated
    session.update!(reauthenticated_at: nil)
    expect(session).not_to be_recently_authenticated
    travel 13.hours do
      expect(user.login_sessions.active).to be_empty
    end
    2.times { session.revoke! }
  end

  it "protège les secrets et coordonnées dans les paramètres journalisés" do
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    parameters = { password: "secret", confirmation_token: "token", email: "private", phone: "private", address_line: "private", reason: "private" }
    expect(filter.filter(parameters).values).to all(eq("[FILTERED]"))
  end
end
