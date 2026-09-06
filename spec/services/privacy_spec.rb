require "rails_helper"
RSpec.describe "Confidentialité et conservation", type: :service do
  let(:user) { create(:user) }
  let(:reviewer) { create(:user, :super_admin) }
  let(:approver) { create(:user, :super_admin) }
  def request_for(kind)
    Privacy.request!(user: user, kind: kind, details: "Demande du membre")
  end
  it "chiffre l’export et exclut les secrets et les autres membres" do
    other = create(:user)
    record = request_for("access")
    expect { Privacy.export!(request: record, actor: other) }.to raise_error(Pundit::NotAuthorizedError)
    Privacy.export!(request: record, actor: user)
    encrypted = record.export_file.download
    expect(encrypted).not_to include(user.email)
    payload = Privacy.encryptor.decrypt_and_verify(encrypted)
    expect(payload).to include(user.email)
    expect(payload).not_to include(other.email, "encrypted_password", "token_digest")
    expect(record).to be_export_available
    travel 25.hours do
      expect(record.reload).not_to be_export_available
      PrivacyMaintenanceJob.perform_now
      expect(record.reload.export_file).not_to be_attached
    end
  end
  it "exige deux personnes distinctes avant un retrait effectif" do
    record = request_for("withdrawal")
    expect { Privacy.review!(request: record, actor: user, response: "Oui") }.to raise_error(Pundit::NotAuthorizedError)
    expect { Privacy.execute!(request: record, actor: approver) }.to raise_error(Exchanges::Invalid)
    Privacy.review!(request: record, actor: reviewer, response: "Les abonnements seront retirés")
    expect { Privacy.execute!(request: record, actor: reviewer) }.to raise_error(Pundit::NotAuthorizedError)
    Privacy.execute!(request: record, actor: approver)
    expect(user.reload.email_notifications).to be(false)
    expect(record.reload.status).to eq("completed")
  end
  it "anonymise le profil et révoque les sessions, avec suivi des prestataires" do
    user.create_profile!(display_name: "Camille", status: "published", phone: "0123456789")
    login, = LoginSession.issue!(user: user, user_agent: "Firefox")
    record = request_for("erasure")
    Privacy.review!(request: record, actor: reviewer, response: "Effacement partiel : preuves en revue séparée")
    Privacy.execute!(request: record, actor: approver)
    expect(user.reload).to be_anonymized
    expect(user.email).to end_with("@deleted.invalid")
    expect(user.unconfirmed_email).to be_nil
    expect(user.profile.reload.phone).to be_nil
    expect(login.reload.revoked_at).to be_present
    expect(record.reload.status).to eq("partial")
    expect(record.provider_erasure_tasks.count).to eq(3)
  end
  it "bloque les durées illimitées, publie après simulation et borne la purge" do
    policy = RetentionPolicyVersion.new(name: "Essai", created_by: reviewer, rules: { "all" => "forever" }, effective_at: 1.minute.from_now, expires_at: 1.year.from_now)
    expect(policy).not_to be_valid
    policy.rules = RetentionPolicyVersion::PURPOSES.index_with { |purpose| purpose == "exports" ? 1 : 30 }
    policy.legal_reviewed_at = Time.current
    policy.save!
    expect { Retention.policy!(policy: policy, actor: approver, action: "publish", reason: "Validation") }.to raise_error(Exchanges::Invalid)
    Retention.policy!(policy: policy, actor: reviewer, action: "simulate", reason: "Simulation")
    expect { Retention.policy!(policy: policy, actor: reviewer, action: "publish", reason: "Validation") }.to raise_error(Exchanges::Invalid)
    Retention.policy!(policy: policy, actor: approver, action: "publish", reason: "Validation")
    travel 2.minutes do
      old = CookieConsent.create!(visitor_digest: "old", version: CookieConsent::VERSION, expires_at: 31.days.ago)
      recent = CookieConsent.create!(visitor_digest: "recent", version: CookieConsent::VERSION, expires_at: 1.day.from_now)
      run = Retention.preview!(actor: reviewer, reason: "Purge approuvée")
      expect(run.targets["cookie_preferences"]).to eq([ old.id ])
      expect { Retention.execute!(run: run, actor: reviewer) }.to raise_error(Pundit::NotAuthorizedError)
      Retention.execute!(run: run, actor: approver)
      expect(CookieConsent.exists?(old.id)).to be(false)
      expect(CookieConsent.exists?(recent.id)).to be(true)
    end
    travel 2.years do
      expect { Retention.preview!(actor: reviewer, reason: "Purge") }.to raise_error(Exchanges::Invalid)
    end
  end
end
