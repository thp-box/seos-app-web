require "rails_helper"
RSpec.describe "Cas limites des services métier", type: :service do
  it "interdit les cycles illégaux de publication et soumet les catégories sensibles à revue" do
    listing = create(:listing, status: :draft)
    invoke = ->(event, actor = listing.user) { ListingWorkflow.call(listing: listing, actor: actor, action: event) }
    expect { invoke.call("publish", create(:user)) }.to raise_error(Pundit::NotAuthorizedError)
    expect { invoke.call("pause") }.to raise_error(Exchanges::Invalid)
    expect { invoke.call("forged") }.to raise_error(Exchanges::Invalid)
    listing.update!(title: nil)
    expect { invoke.call("publish") }.to raise_error(ActiveRecord::RecordInvalid)
    listing.update!(title: "Un atelier", service_location_mode: "in_person")
    expect { invoke.call("publish") }.to have_enqueued_job(GeocodeListingJob)
    expect { invoke.call("publish") }.to raise_error(Exchanges::Invalid)
  end

  it "interdit propositions et accords après blocage et ne confirme pas sans accord" do
    request = create(:service_request, status: :accepted)
    args = { request: request, actor: request.provider }
    terms = { scheduled_at: 1.day.from_now.iso8601, location: "Visioconférence", mode: "remote" }
    Exchanges.transition!(**args, action: "propose", terms: terms)
    Exchanges.transition!(**args, action: "agree", version: 1)
    expect(request).to be_accepted
    block = UserBlock.create!(user: request.provider, blocked_user: request.requester)
    expect { Exchanges.transition!(**args, action: "propose", terms: terms) }.to raise_error(Exchanges::Invalid)
    expect { Exchanges.transition!(**args, actor: request.requester, action: "agree", version: 1) }.to raise_error(Exchanges::Invalid)
    block.destroy!
    request.update!(status: :scheduled, requester_agreed_at: nil)
    expect { Exchanges.transition!(**args, action: "confirm") }.to raise_error(Exchanges::Invalid)
  end

  it "refuse la réutilisation d’une clé de message dans une autre conversation et les conversations closes" do
    first = create(:service_request)
    second = create(:service_request, requester: first.requester)
    Exchanges.message!(request: first, actor: first.requester, body: "Premier message", key: "same-key")
    expect { Exchanges.message!(request: second, actor: second.requester, body: "Autre conversation", key: "same-key") }.to raise_error(Exchanges::Invalid)
    second.update!(status: :cancelled)
    expect { Exchanges.message!(request: second, actor: second.requester, body: "Trop tard", key: "new-key") }.to raise_error(Exchanges::Invalid)
  end

  it "garde les partages privés après révocation par profil ou annulation" do
    request = create(:service_request, status: :scheduled, requester_agreed_at: Time.current, provider_agreed_at: Time.current, provider_shared_at: Time.current)
    request.provider.profile.update!(phone: "0612345678")
    expect(request.shared_contact_for(request.requester)).not_to be_empty
    request.provider.profile.update!(phone_sharing_policy: "nobody")
    expect(request.shared_contact_for(request.requester)).to be_empty
    Exchanges.transition!(request: request, actor: request.requester, action: "cancel", reason: "Indisponibilité")
    expect(request).to be_cancelled
    expect(request.shared_contact_for(request.requester)).to be_empty
  end

  it "gère un géocodage vide et une commune changée pendant la requête" do
    expect(PublicGeocoding.coordinates("")).to be_nil
    listing = create(:listing, service_location_mode: "in_person", city: "Amiens")
    allow(Geocoder).to receive(:search).and_return([])
    GeocodeListingJob.perform_now(listing)
    expect(listing.reload.latitude).to be_nil
    allow(Geocoder).to receive(:search) do
      listing.update!(city: "Lille")
      [ double(coordinates: [ 49.89, 2.3 ]) ]
    end
    GeocodeListingJob.perform_now(listing)
    expect(listing.reload.latitude).to be_nil
  end

  it "traite uniquement les annonces qui correspondent à une restriction de pause" do
    listing = create(:listing)
    unaffected = create(:listing, title: "Apprendre une langue", description: "Conversation en français")
    restriction = CategoryRestriction.create!(category: listing.category, created_by: create(:user, :super_admin), starts_at: Time.current, reason: "Revue", existing_action: "pause")
    expect(restriction.matches?(Listing.new)).to be_falsey
    ApplyCategoryRestrictionsJob.perform_now
    expect(listing.reload).to be_paused
    expect(unaffected.reload).to be_published
    expect(Catalogue.call(ActionController::Parameters.new(intent: "offer"))).to eq([ unaffected ])
  end

  it "échoue proprement sur les brouillons incomplets et participants forgés" do
    user = create(:user)
    listing = Listing.new(user: user, status: :draft)
    expect(listing.valid?(:publication)).to be(false)
    listing.category = create(:category, sensitive: true)
    expect(listing.valid?(:publication)).to be(false)
    expect(Message.new(sender: user, body: "Message", delivery_key: "orphan")).not_to be_valid
    real = create(:service_request)
    expect(Message.new(service_request: real, sender: user, body: "Intrusion", delivery_key: "forged")).not_to be_valid
    real.provider = user
    expect(real).not_to be_valid
  end

  it "refuse les bombes de décompression et les images illisibles" do
    path = Rails.root.join("tmp", "oversize-image.png")
    Vips::Image.black(5000, 5000).pngsave(path.to_s)
    upload = Rack::Test::UploadedFile.new(path, "image/png")
    expect { SafeImage.attach!(create(:listing).photos, upload) }.to raise_error(Exchanges::Invalid, /millions de pixels/)
    File.binwrite(path, "\x89PNG\r\n\x1a\nCorrupted".b)
    invalid = Rack::Test::UploadedFile.new(path, "image/png")
    expect { SafeImage.attach!(create(:listing).photos, invalid) }.to raise_error(Exchanges::Invalid)
  ensure
    FileUtils.rm_f(path)
  end
end
