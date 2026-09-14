require "rails_helper"
RSpec.describe "Étapes de création des annonces", type: :request do
  it "garde les champs dans leur étape et refuse de poursuivre un formulaire incomplet" do
    user = create(:profile).user
    login(user)
    post account_listings_path(step: 1), params: { listing: { intent: "request", title: "Titre imposé", status: "published" } }
    draft = user.listings.last
    expect(draft).to have_attributes(intent: "request", title: nil, status: "draft")
    patch account_listing_path(draft, step: 2), params: { listing: { exchange_mode: "points" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(draft.reload.exchange_mode).to eq("gift")
    patch account_listing_path(draft, step: 2), params: { listing: { exchange_mode: "points", estimated_points: 25 } }
    expect(response).to have_http_status(:see_other)
    get edit_account_listing_path(draft, step: 3)
    expect(response.body).to include("Un coup de main pour apprendre la guitare")
    expect(draft.reload.title).to be_nil
    patch account_listing_path(draft, step: 3), params: { listing: { title: "Ma demande", description: "Je cherche de l’aide", city: "" } }
    expect(response).to have_http_status(:unprocessable_content)
    expect(draft.reload.title).to be_nil
    patch transition_account_listing_path(draft), params: { event: "publish", privacy_confirmed: "1" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(draft.reload).to be_draft
  end
end
