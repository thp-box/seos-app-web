require "rails_helper"

RSpec.describe "Filtres visuels du catalogue", type: :request do
  it "combine les catégories, les modes et le plafond sans exclure les dons" do
    parent = create(:category)
    child = create(:category, parent: parent)
    other = create(:category)
    gift = create(:listing, category: child)
    affordable = create(:listing, category: other, exchange_mode: "points", estimated_points: 25)
    expensive = create(:listing, category: child, exchange_mode: "points", estimated_points: 100)
    barter = create(:listing, category: child, exchange_mode: "barter")
    get listings_path, params: { category_ids: [ parent.id, other.id ], exchange_modes: %w[gift points], max_points: 60 }
    expect(response).to have_http_status(:ok)
    ids = Nokogiri::HTML(response.body).css('.catalogue-card h3 a').map { |link| link['href'] }
    expect(ids).to contain_exactly(listing_path(gift), listing_path(affordable))
    get listings_path, params: { exchange_modes: [ "" ], max_points: 200 }
    expect(response.body).to include("Aucun résultat")
    get listings_path, params: { exchange_modes: %w[points], max_points: 200 }
    expect(Nokogiri::HTML(response.body).css('.catalogue-card h3 a').map { |link| link['href'] }).to contain_exactly(listing_path(affordable), listing_path(expensive))
    expect(Catalogue.call(category_id: parent.id, exchange_mode: "barter")).to eq([ barter ])
  end
end
