require "rails_helper"
RSpec.describe Exchanges, :"F-020", :"F-021", :"F-022", type: :service do
  let!(:listing) { create(:listing) }
  let(:provider) { listing.user }
  let(:requester) { create(:profile).user }
  let(:stranger) { create(:user) }
  let(:request) { described_class.create!(listing: listing, actor: requester) }
  def transition(event, actor: provider, **options)
    described_class.transition!(request: request, actor: actor, action: event, **options)
  end
  def propose(**terms)
    transition("propose", terms: { scheduled_at: 1.day.from_now.iso8601, location: "Appel privé", mode: "remote" }.merge(terms))
  end
  def agree
    transition("accept")
    propose
    transition("agree", actor: requester, version: request.agreement_version)
  end

  it "interdit auto-demande, annonce fermée et blocage, et déduplique une demande" do
    expect { described_class.create!(listing: listing, actor: provider) }.to raise_error(Exchanges::Invalid)
    expect(described_class.create!(listing: listing, actor: requester)).to eq(request)
    expect(ServiceRequest.count).to eq(1)
    listing.update!(status: :closed)
    expect { described_class.create!(listing: listing, actor: stranger) }.to raise_error(Exchanges::Invalid)
    listing.update!(status: :published)
    UserBlock.create!(user: provider, blocked_user: stranger)
    expect { described_class.create!(listing: listing, actor: stranger) }.to raise_error(Exchanges::Invalid)
  end

  it "refuse les acteurs tiers, les transitions illégales et les demandes expirées" do
    expect { transition("accept", actor: requester) }.to raise_error(Pundit::NotAuthorizedError)
    expect { transition("accept", actor: stranger) }.to raise_error(Pundit::NotAuthorizedError)
    expect { transition("confirm") }.to raise_error(Exchanges::Invalid)
    expect { transition("inconnue") }.to raise_error(Exchanges::Invalid)
    request.update!(expires_at: 1.minute.ago)
    expect { transition("accept") }.to raise_error(Exchanges::Invalid)
    replacement = described_class.create!(listing: listing, actor: requester)
    expect(replacement.id).not_to eq(request.id)
    expect(request.reload).to be_expired
  end

  it "gère le refus et empêche d’accepter une annonce qui vient d’être fermée ou bloquée" do
    transition("decline")
    expect(request).to be_declined
    request.update!(status: :pending)
    listing.update!(status: :closed)
    expect { transition("accept") }.to raise_error(Exchanges::Invalid)
    listing.update!(status: :published)
    UserBlock.create!(user: provider, blocked_user: requester)
    expect { transition("accept") }.to raise_error(Exchanges::Invalid)
  end

  it "requiert un accord commun, chiffre ses termes et annule les acceptations après modification" do
    transition("accept")
    expect { transition("agree", actor: requester, version: 0) }.to raise_error(Exchanges::Invalid)
    expect { propose(scheduled_at: "invalide") }.to raise_error(Exchanges::Invalid)
    expect { propose(mode: "inconnu") }.to raise_error(Exchanges::Invalid)
    expect { propose(points: "10") }.to raise_error(Exchanges::Invalid)
    propose
    expect(request.reload.agreement["location"]).to eq("Appel privé")
    expect(request.read_attribute_before_type_cast(:agreement).to_s).not_to include("Appel privé")
    expect { transition("agree", actor: requester, version: 99) }.to raise_error(Exchanges::Invalid)
    transition("agree", actor: requester, version: request.agreement_version)
    expect(request).to be_scheduled
    propose(location: "Nouveau lieu privé")
    expect(request.requester_agreed_at).to be_nil
    expect(request).to be_accepted
    expect { transition("confirm") }.to raise_error(Exchanges::Invalid)
  end

  it "valide les montants PS et la contrepartie du troc" do
    point_rules
    listing.update!(exchange_mode: "points", estimated_points: 20)
    transition("accept")
    expect { propose(points: "0") }.to raise_error(Exchanges::Invalid)
    propose(points: "20")
    expect(request.agreement["points"]).to eq(20)
    listing.update!(exchange_mode: "barter")
    expect { propose }.to raise_error(Exchanges::Invalid)
    propose(consideration: "Atelier cuisine contre jardinage")
    expect(request.agreement["consideration"]).to include("cuisine")
  end

  it "partage puis révoque des coordonnées uniquement pour cet accord" do
    agree
    provider.profile.update!(phone: "0612345678", address_line: "Lieu secret")
    expect(request.shared_contact_for(requester)).to be_empty
    transition("share")
    expect(request.shared_contact_for(requester)[:phone]).to eq("0612345678")
    expect(request.shared_contact_for(stranger)).to be_empty
    transition("revoke")
    expect(request.shared_contact_for(requester)).to be_empty
    provider.profile.update!(phone_sharing_policy: "nobody")
    expect { transition("share") }.to raise_error(Exchanges::Invalid)
  end

  it "exige deux confirmations, chacune idempotente, et conserve un historique immuable" do
    agree
    transition("confirm")
    expect(request).to be_awaiting_confirmation
    expect { transition("confirm") }.not_to change(RequestEvent, :count)
    second_instance = ServiceRequest.find(request.id)
    described_class.transition!(request: second_instance, actor: requester, action: "confirm")
    expect(request.reload).to be_completed
    expect { transition("confirm") }.not_to change(RequestEvent, :count)
    expect(request.completed_at).to be_present
    expect { RequestEvent.first.update_column(:kind, "forged") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    expect { RequestEvent.where(id: RequestEvent.first.id).delete_all }.to raise_error(ActiveRecord::StatementInvalid)
  end

  it "ouvre un dossier de litige, et permet une annulation neutre motivée" do
    expect { transition("cancel", reason: "") }.to raise_error(Exchanges::Invalid)
    transition("dispute", actor: requester, reason: "Nous avons besoin d’une médiation")
    expect(request).to be_disputed
    expect(Report.last.reportable).to eq(request)
    request.update!(status: :accepted)
    transition("cancel", reason: "Indisponibilité commune")
    expect(request).to be_cancelled
    expect(request.requester_shared_at).to be_nil
  end

  it "chiffre les messages, déduplique un envoi et sa notification, et contrôle le blocage" do
    first = described_class.message!(request: request, actor: requester, body: "Contenu confidentiel", key: "cle-1")
    expect(first.reload.body).to eq("Contenu confidentiel")
    expect(first.read_attribute_before_type_cast(:body)).not_to include("Contenu confidentiel")
    expect { described_class.message!(request: request, actor: requester, body: "Doublon", key: "cle-1") }.not_to change(Notification, :count)
    expect { described_class.message!(request: request, actor: stranger, body: "Interdit", key: "cle-2") }.to raise_error(Pundit::NotAuthorizedError)
    UserBlock.create!(user: provider, blocked_user: requester)
    expect { described_class.message!(request: request, actor: requester, body: "Bloqué", key: "cle-3") }.to raise_error(Exchanges::Invalid)
  end
end
