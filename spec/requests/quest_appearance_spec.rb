require "rails_helper"

RSpec.describe "Apparence des quêtes", type: :request do
  before { point_rules }

  it "rejette les styles inconnus et conserve les règles et les permissions" do
    admin = create(:user, :admin)
    login(admin)
    attributes = { operation: "quest", name: "Jardin", description: "Aider les voisins", reward_key: "share", recurrence: "once", icon: "heart", accent: "forest", reason: "Campagne" }
    post admin_community_index_path, params: attributes
    expect(response).to have_http_status(:forbidden)
    grant(admin, "community.manage")
    expect { post admin_community_index_path, params: attributes.merge(accent: "unknown") }.not_to change(Achievement, :count)
    expect(response).to have_http_status(:unprocessable_content)
    post admin_community_index_path, params: attributes
    expect(response).to have_http_status(:see_other)
    quest = Achievement.last
    post admin_community_index_path, params: { operation: "quest_update", record_id: quest.id, icon: "trophy", accent: "plum", animated: false, target_count: 99, reward_key: "welcome", reason: "Nouvelle apparence" }
    expect(response).to have_http_status(:see_other)
    expect(quest.reload).to have_attributes(icon: "trophy", accent: "plum", animated: false, target_count: 1, reward_key: "share")
  end
end
