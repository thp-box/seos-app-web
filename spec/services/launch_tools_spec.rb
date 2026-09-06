require "rails_helper"
RSpec.describe "Outils de lancement", type: :service do
  let(:actor) { create(:user, :super_admin) }
  let(:second) { create(:user, :super_admin) }
  let(:user) { create(:user) }
  it "valide, publie et restaure le défaut sans modifier l’historique" do
    version = Studio.change!(actor: actor, name: "Variante", settings: { "tokens" => { "radius" => "18px" }, "pages" => { "home" => { "title" => "Bonjour" } } })
    expect { Studio.transition!(version: version, actor: actor, action: "publish", reason: "Test") }.to raise_error(Exchanges::Invalid)
    Studio.transition!(version: version, actor: actor, action: "validate", reason: "Contrôles")
    Studio.transition!(version: version, actor: actor, action: "publish", reason: "Validé")
    expect(StudioVersion.current).to eq(version)
    expect { version.update!(name: "Modifié") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { StudioVersion.where(id: version.id).update_all(name: "SQL") }.to raise_error(ActiveRecord::StatementInvalid)
    reset = Studio.change!(actor: actor, name: "Défaut", settings: {}, source: version, reset: "site")
    expect(reset.settings).to eq({})
    expect(version.reload.page("home")["title"]).to eq("Bonjour")
  end
  it "refuse le code libre et les contrastes insuffisants" do
    expect { Studio.change!(actor: actor, name: "CSS", settings: { "tokens" => { "radius" => "url(https://example.test)" } }) }.to raise_error(ActiveRecord::RecordInvalid)
    version = Studio.change!(actor: actor, name: "Illisible", settings: { "tokens" => { "ink" => "#FFFFFF" } })
    expect { Studio.transition!(version: version, actor: actor, action: "validate", reason: "Test") }.to raise_error(Exchanges::Invalid)
    expect { Studio.change!(actor: user, name: "Interdit", settings: {}) }.to raise_error(Pundit::NotAuthorizedError)
  end
  it "fige une sélection, interdit l’auto-approbation et révoque les sessions" do
    login, = LoginSession.issue!(user: user, user_agent: "Firefox")
    operation = Operations.preview!(actor: actor, ids: [ user.id ], reason: "Abus vérifié")
    expect { Operations.execute!(operation: operation, actor: actor) }.to raise_error(Pundit::NotAuthorizedError)
    Operations.execute!(operation: operation, actor: second)
    expect(user.reload).to be_suspended
    expect(login.reload.revoked_at).to be_present
    expect { Operations.execute!(operation: operation, actor: second) }.not_to change(AuditLog, :count)
    expect { Operations.preview!(actor: actor, ids: [ second.id ], reason: "Interdit") }.to raise_error(Exchanges::Invalid)
  end
  it "expire la blacklist et ne conserve pas l’adresse en clair" do
    LoginBlock.create!(actor: actor, email_digest: LoginBlock.digest(user.email), reason: "Abus", expires_at: 1.hour.from_now)
    expect(user).not_to be_active_for_authentication
    expect(LoginBlock.last.email_digest).not_to include(user.email)
    travel 2.hours do
      expect(user).to be_active_for_authentication
    end
  end
  it "lie Google seulement depuis un compte authentifié et refuse les membres suspendus" do
    auth = { "provider" => "google_oauth2", "uid" => "google-sub-123", "info" => { "email_verified" => true, "email" => user.email } }
    expect { GoogleIdentity.resolve!(auth: auth) }.to raise_error(Exchanges::Invalid)
    expect(GoogleIdentity.resolve!(auth: auth, user: user)).to eq(user)
    expect(GoogleIdentity.resolve!(auth: auth)).to eq(user)
    expect { GoogleIdentity.resolve!(auth: auth, user: actor) }.to raise_error(Exchanges::Invalid)
    user.update!(status: "suspended")
    expect { GoogleIdentity.resolve!(auth: auth) }.to raise_error(Pundit::NotAuthorizedError)
    expect { GoogleIdentity.resolve!(auth: auth.merge("provider" => "fake")) }.to raise_error(Exchanges::Invalid)
  end
  it "envoie du MIME par Gmail et réconcilie une réponse perdue sans renvoyer" do
    %w[GMAIL_CLIENT_ID GMAIL_CLIENT_SECRET GMAIL_REFRESH_TOKEN].each { |key| allow(ENV).to receive(:fetch).with(key).and_return("test") }
    stub_request(:post, "https://oauth2.googleapis.com/token").to_return(body: { access_token: "token" }.to_json)
    mail = Mail.new(from: "from@example.test", to: "to@example.test", subject: "Test", body: "Bonjour", message_id: "test@seos.test")
    send_stub = stub_request(:post, "https://gmail.googleapis.com/gmail/v1/users/me/messages/send").to_return(body: { id: "sent-1" }.to_json)
    delivery = SeosMail::Gmail.new
    2.times { delivery.deliver!(mail) }
    expect(send_stub).to have_been_requested.once
    expect(MailDelivery.last.status).to eq("sent")
    MailDelivery.last.update!(status: "uncertain")
    stub_request(:get, "https://gmail.googleapis.com/gmail/v1/users/me/messages").with(query: { q: "rfc822msgid:test@seos.test" }).to_return(body: { messages: [ { id: "sent-1" } ] }.to_json)
    delivery.deliver!(mail)
    expect(send_stub).to have_been_requested.once
    expect(MailDelivery.last.status).to eq("sent")
  end
end

RSpec.describe "Défaillances Gmail", type: :service do
  it "ne réémet pas après une erreur ambiguë et n’expose pas la réponse fournisseur" do
    %w[GMAIL_CLIENT_ID GMAIL_CLIENT_SECRET GMAIL_REFRESH_TOKEN].each { |key| allow(ENV).to receive(:fetch).with(key).and_return("test") }
    stub_request(:post, "https://oauth2.googleapis.com/token").to_return(body: { access_token: "token" }.to_json)
    mail = Mail.new(from: "from@example.test", to: "to@example.test", body: "Bonjour", message_id: "ambiguous@seos.test")
    send_stub = stub_request(:post, "https://gmail.googleapis.com/gmail/v1/users/me/messages/send").to_return(status: 503, body: "SECRET-FOURNISSEUR")
    expect { SeosMail::Gmail.new.deliver!(mail) }.to raise_error(SeosMail::Gmail::ProviderError, /503/)
    expect(MailDelivery.last.status).to eq("uncertain")
    stub_request(:get, "https://gmail.googleapis.com/gmail/v1/users/me/messages").with(query: { q: "rfc822msgid:ambiguous@seos.test" }).to_return(body: "{}")
    expect { SeosMail::Gmail.new.deliver!(mail) }.to raise_error(SeosMail::Gmail::UncertainDelivery)
    expect(send_stub).to have_been_requested.once
    stub_request(:post, "https://oauth2.googleapis.com/token").to_return(body: "invalid json")
    expect { SeosMail::Gmail.new.deliver!(mail) }.to raise_error(SeosMail::Gmail::ProviderError)
  end
end

RSpec.describe "Reset éditorial", type: :service do
  it "restaure plusieurs pages dans de nouvelles versions sans toucher leur historique" do
    actor = create(:user, :super_admin)
    originals = %w[don echange].map { |slug| create(:content_version, author: actor, kind: "page", slug: slug, title: "Titre d’origine #{slug}", published_at: 2.days.ago) }
    originals.each { |original| create(:content_version, author: actor, kind: "page", slug: original.slug, version: 2, title: "Titre modifié", published_at: 1.day.ago) }
    reset = Studio.change!(actor: actor, settings: {}, name: "Restaurer le site", reset: "site")
    expect(reset.settings["editorial_resets"]).to match_array(originals.map(&:id))
    expect(ContentVersion.current("page", "don").title).to eq("Titre modifié")
    %w[validate publish].each { |action| Studio.transition!(version: reset, actor: actor, action: action, reason: "Retour validé") }
    originals.each do |original|
      current = ContentVersion.current("page", original.slug)
      expect(current.title).to eq(original.title)
      expect(current.version).to eq(3)
      expect(original.reload.title).to include("origine")
    end
    expect { Studio.transition!(version: reset, actor: actor, action: "publish", reason: "Rejouer") }.to raise_error(Exchanges::Invalid)
  end
end
