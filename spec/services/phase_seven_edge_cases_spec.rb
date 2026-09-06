require "rails_helper"
RSpec.describe "Limites des outils de lancement", type: :service do
  let(:actor) { create(:user, :super_admin) }
  let(:second) { create(:user, :super_admin) }
  let(:user) { create(:profile).user }
  it "refuse les sélections trop grandes, modifiées ou expirées" do
    expect { Operations.preview!(actor: user, ids: [ user.id ], reason: "Test") }.to raise_error(Pundit::NotAuthorizedError)
    expect { Operations.preview!(actor: actor, ids: [], reason: "Test") }.to raise_error(Exchanges::Invalid)
    operation = Operations.preview!(actor: actor, ids: [ user.id ], reason: "Test")
    user.update!(email_notifications: false)
    expect { Operations.execute!(operation: operation, actor: second) }.to raise_error(Exchanges::Invalid)
    operation = Operations.preview!(actor: actor, ids: [ user.id ], reason: "Test")
    travel 16.minutes do
      expect { Operations.execute!(operation: operation, actor: second) }.to raise_error(Exchanges::Invalid)
    end
  end
  it "limite et rectifie sans prétendre effacer les registres financiers" do
    %w[restriction objection rectification].each do |kind|
      target = create(:user)
      record = Privacy.request!(user: target, kind: kind, details: "Demande")
      expect { Privacy.export!(request: record, actor: target) }.to raise_error(Exchanges::Invalid)
      expect { Privacy.review!(request: record, actor: actor, response: "") }.to raise_error(Exchanges::Invalid)
      Privacy.review!(request: record, actor: actor, response: "Dossier vérifié")
      Privacy.execute!(request: record, actor: second)
      expect(record.reload.status).to eq("completed")
      expect { Privacy.review!(request: record, actor: actor, response: "Rejouer") }.to raise_error(Exchanges::Invalid)
    end
  end
  it "protège un administrateur de l’anonymisation et efface les pièces du membre" do
    record = Privacy.request!(user: actor, kind: "erasure", details: "Demande")
    reviewer = create(:user, :super_admin)
    Privacy.review!(request: record, actor: reviewer, response: "Test")
    expect { Privacy.execute!(request: record, actor: second) }.to raise_error(Exchanges::Invalid)
    listing = create(:listing, user: user)
    record = Privacy.request!(user: user, kind: "erasure", details: "Demande")
    Privacy.review!(request: record, actor: actor, response: "Les données publiques seront retirées")
    Privacy.execute!(request: record, actor: second)
    expect(listing.reload.title).to eq("Annonce retirée")
    expect(record.response).to include("Effacement partiel")
  end
  it "refuse les configurations libres, les champs inconnus et un reset invalide" do
    [ [], { "bad" => true }, { "pages" => { "unknown" => {} } }, { "pages" => { "home" => { "image" => "seos-logo.png" } } }, { "pages" => { "home" => { "title" => "<script>" } } } ].each do |settings|
      expect(StudioVersion.new(author: actor, name: "Test", settings: settings)).not_to be_valid
    end
    admin = create(:user, :admin)
    create(:admin_permission_grant, user: admin, permission: "content.manage")
    expect { Studio.change!(actor: admin, name: "Thème", settings: { "tokens" => { "radius" => "12px" } }) }.to raise_error(Pundit::NotAuthorizedError)
    version = Studio.change!(actor: actor, name: "Thème", settings: { "tokens" => { "motion" => "none" }, "pages" => { "home" => { "image" => "seos-logo.png", "alt" => "Logo", "separator" => "wave_single", "animated" => false } } })
    expect(version.css).to include("animation:none")
    expect { Studio.change!(actor: actor, name: "Reset", settings: {}, source: version, reset: "unknown") }.to raise_error(Exchanges::Invalid)
    reset = Studio.change!(actor: actor, name: "Reset", settings: {}, source: version, reset: "pages.home.image")
    expect(reset.page("home")).not_to have_key("image")
    expect { Studio.transition!(version: version, actor: actor, action: "invalid", reason: "Test") }.to raise_error(Exchanges::Invalid)
  end
  it "refuse les politiques expirées et les purges non autorisées" do
    policy = RetentionPolicyVersion.new(name: "Test", rules: RetentionPolicyVersion::PURPOSES.index_with { 1 }, effective_at: Time.current, expires_at: 3.years.from_now)
    expect(policy).not_to be_valid
    expect { Retention.policy!(policy: policy, actor: user, action: "simulate", reason: "Test") }.to raise_error(Pundit::NotAuthorizedError)
    expect { Retention.preview!(actor: user, reason: "Test") }.to raise_error(Pundit::NotAuthorizedError)
    policy.expires_at = 1.year.from_now
    policy.save!
    expect { Retention.policy!(policy: policy, actor: actor, action: "invalid", reason: "Test") }.to raise_error(Exchanges::Invalid)
  end
end

RSpec.describe "Purge approuvée", type: :service do
  it "expire la simulation, puis supprime uniquement les éléments encore éligibles" do
    actor = create(:user, :super_admin)
    second = create(:user, :super_admin)
    user = create(:user)
    policy = RetentionPolicyVersion.create!(name: "Recette", created_by: actor, rules: RetentionPolicyVersion::PURPOSES.index_with { 1 }, effective_at: 1.minute.from_now, expires_at: 1.year.from_now, legal_reviewed_at: Time.current)
    Retention.policy!(policy: policy, actor: actor, action: "simulate", reason: "Recette")
    Retention.policy!(policy: policy, actor: second, action: "publish", reason: "Recette")
    travel 2.minutes do
      session, = LoginSession.issue!(user: user, user_agent: "Test")
      session.update!(revoked_at: 2.days.ago)
      notification = Notification.create!(user: user, event_key: "old", title: "Information", created_at: 2.days.ago)
      contact = ContactRequest.create!(email: user.email, subject: "Aide", message: "Bonjour", status: "resolved", resolved_at: 2.days.ago)
      request = Privacy.request!(user: user, kind: "access", details: "")
      Privacy.export!(request: request, actor: user)
      request.update!(export_expires_at: 1.second.ago)
      run = Retention.preview!(actor: actor, reason: "Purge")
      run.update!(expires_at: 1.second.ago)
      expect { Retention.execute!(run: run, actor: second) }.to raise_error(Exchanges::Invalid)
      run = Retention.preview!(actor: actor, reason: "Purge revue")
      Retention.execute!(run: run, actor: second)
      expect(LoginSession.exists?(session.id)).to be(false)
      expect(Notification.exists?(notification.id)).to be(false)
      expect(ContactRequest.exists?(contact.id)).to be(false)
      expect { Retention.execute!(run: run, actor: second) }.not_to change(AuditLog, :count)
    end
  end
end
