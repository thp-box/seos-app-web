require "rails_helper"
RSpec.describe "Découverte, publication et confidentialité", :"F-011", :"F-013", :"F-014", type: :request do
  let!(:listing) { create(:listing) }
  let(:owner) { listing.user }
  let(:member) { create(:profile).user }

  it "rend catalogue, profil, annonce et JSON-LD sans coordonnées privées" do
    owner.profile.update!(phone: "0612345678", address_line: "17 rue Confidentielle")
    listing.update!(address_line: "19 rue Privée")
    [ listings_path, profile_path(owner.profile), listing_path(listing) ].each do |path|
      get path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(owner.email, "0612345678", "rue Confidentielle", "rue Privée")
    end
    doc = Nokogiri::HTML(response.body)
    schema = JSON.parse(doc.at_css('script[type="application/ld+json"]').text)
    expect(schema["@type"]).to eq("Service")
    expect(schema["name"]).to eq(listing.title)
    expect(doc.css('link[rel="canonical"]').size).to eq(1)
    expect(response.body).not_to include('data-public-map')
    get sitemap_path
    expect(response.body).to include(listing_url(listing))
    get "/robots.txt"
    expect(response.body).to include("OAI-SearchBot", "GPTBot")
  end

  it "garde les résultats à distance dans la carte et retire tout chargement lorsque le flag est coupé" do
    local = create(:listing, service_location_mode: "in_person", city: "Paris")
    local.update!(latitude: 48.85661, longitude: 2.35222)
    get listings_path(view: "map")
    expect(response.body).to include(listing.title, local.title, "data-public-map", "48.86")
    expect(response.body).not_to include("48.85661")
    FeatureFlag.find_or_create_by!(key: "public_map_enabled").update!(enabled: false)
    [ listings_path(view: "map"), listing_path(local) ].each do |path|
      get path
      expect(response.body).not_to include("data-public-map", "map.js", "map.css", "Vue carte")
    end
  end

  it "cache brouillons, propriétaires suspendus et profils restreints, et retourne 410 après retrait" do
    %w[draft pending_review paused closed].each do |status|
      listing.update!(status: status)
      get listing_path(listing)
      expect(response).to have_http_status(:not_found)
    end
    listing.update!(status: :removed)
    get listing_path(listing)
    expect(response).to have_http_status(:gone)
    listing.update!(status: :published)
    owner.profile.update!(status: :restricted)
    get listing_path(listing)
    expect(response).to have_http_status(:not_found)
    get profile_path(owner.profile)
    expect(response).to have_http_status(:not_found)
  end

  it "publie en quatre étapes sans accepter les champs de propriétaire ou de statut" do
    login member
    expect { get new_account_listing_path }.not_to change(Listing, :count)
    expect(response).to have_http_status(:ok)
    post account_listings_path(step: 1), params: { listing: { category_id: listing.category_id, intent: "offer", exchange_mode: "gift", service_location_mode: "remote", user_id: owner.id, status: "published" } }
    draft = member.listings.last
    expect(draft).to be_draft
    patch account_listing_path(draft, step: 2), params: { listing: { title: "Cours de français", description: "Nous pratiquons la conversation ensemble.", lock_version: draft.lock_version } }
    expect(response).to have_http_status(:see_other)
    get edit_account_listing_path(draft, step: 4)
    expect(response.body).to include("Cours de français")
    patch transition_account_listing_path(draft), params: { event: "publish", privacy_confirmed: "1" }
    expect(response).to have_http_status(:see_other)
    expect(draft.reload).to be_published
    patch transition_account_listing_path(draft), params: { event: "pause" }
    expect(draft.reload).to be_paused
    get account_listings_path
    expect(response).to have_http_status(:ok)
    patch account_listing_path(listing, step: 2), params: { listing: { title: "Usurpation" } }
    expect(response).to have_http_status(:forbidden)
    expect(listing.reload.title).not_to eq("Usurpation")
  end

  it "édite son profil chiffré et refuse les coordonnées dans la biographie publique" do
    login member
    get edit_account_profile_path
    expect(response).to have_http_status(:ok)
    patch account_profile_path, params: { profile: { display_name: "Pseudonyme", phone: "0612345678", address_line: "Adresse secrète", role: "super_admin" } }
    expect(response).to have_http_status(:see_other)
    expect(member.reload).to be_member
    profile = member.profile.reload
    expect(profile.phone).to eq("0612345678")
    expect(profile.read_attribute_before_type_cast(:phone)).not_to include("0612345678")
    patch account_profile_path, params: { profile: { bio: "Contact : prive@example.test" } }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "gère favoris privés et commentaires séparés des avis" do
    login member
    2.times { post account_favorites_path, params: { listing_slug: listing.slug } }
    expect(member.favorites.count).to eq(1)
    get account_favorites_path
    expect(response).to have_http_status(:ok)
    post account_comments_path, params: { listing_slug: listing.slug, comment: { body: "Quel matériel faut-il prévoir ?" } }
    comment = Comment.last
    get listing_path(listing)
    expect(response.body).to include("Quel matériel")
    delete account_comment_path(comment)
    expect(comment.reload.removed_at).to be_present
    delete account_favorite_path(listing.id)
    expect(member.favorites.count).to eq(0)
  end

  it "limite le contact visiteur à l’équipe et applique l’anti-spam" do
    get contact_path
    expect(response).to have_http_status(:ok)
    expect do
      post contact_path, params: { contact_request: { email: "visiteur@example.test", subject: "Question", message: "Comment rejoindre SEOS ?", provider_id: owner.id } }
    end.to change(ContactRequest, :count).by(1)
    expect(ServiceRequest.count).to eq(0)
    expect(Message.count).to eq(0)
    post contact_path, params: { website: "spam", contact_request: { email: "spam@example.test" } }
    expect(ContactRequest.count).to eq(1)
    post contact_path, params: { contact_request: { email: "invalide" } }
    expect(response).to have_http_status(:unprocessable_entity)
    3.times { post contact_path, params: { contact_request: { email: "invalide" } } }
    expect(response).to have_http_status(:too_many_requests)
  end
end
