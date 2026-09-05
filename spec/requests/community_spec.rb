require "rails_helper"

RSpec.describe "Parcours communautaires", type: :request do
  let(:user) { create(:profile).user }
  let(:admin) { create(:user, :super_admin) }
  before { point_rules; load Rails.root.join("db/community_seeds.rb") }

  it "conserve l’invitation après connexion et n’accepte aucun identifiant imposé" do
    chain = Chains.create!(actor: user, name: "Le relais privé")
    service, token = Chains.invite!(chain: chain, actor: user, description: "Réparer une étagère")
    get chain_invitation_path(invitation_token: token)
    expect(response).to redirect_to(new_user_session_path)
    expect(response.headers["Referrer-Policy"]).to eq("no-referrer")
    beneficiary = create(:profile).user
    login beneficiary
    expect(response).to redirect_to(chain_invitation_path)
    get chain_invitation_path
    expect(response.body).to include("Réparer une étagère")
    expect(response.body).not_to include(user.email)
    post chain_invitation_path, params: { service_id: 99999, amount: 99999 }
    expect(response).to redirect_to(account_chain_path(chain))
    expect(service.reload.beneficiary).to eq(beneficiary)
    get account_chain_path(chain)
    expect(response.body).to include("10 PS", "longueur", "illimitée")
    get chain_invitation_path(invitation_token: token)
    expect(response).to have_http_status(:unprocessable_content)
    get account_chains_path
    expect(response.body).to include("Le relais privé")
    patch account_chain_path(chain), params: { description: "Un nouveau service" }
    expect(response.body).to include("Lien privé de confirmation")
    expect(response.headers["Cache-Control"]).to include("no-store")
    delete destroy_user_session_path
    login create(:user)
    get account_chain_path(chain)
    expect(response).to have_http_status(:forbidden)
    post chain_invitation_path, params: { service_id: service.id }
    expect(response).to have_http_status(:not_found)
    post account_chains_path, params: { name: "Ma nouvelle chaîne" }
    expect(response).to have_http_status(:see_other)
  end

  it "affiche les quêtes privées et gère les témoignages consentis et leur retrait" do
    get account_community_path
    expect(response).to redirect_to(new_user_session_path)
    get testimonials_path
    expect(response).to have_http_status(:ok)
    login user
    get account_community_path
    expect(response.body).to include("Mes quêtes", "Bronze")
    post account_community_path, params: { operation: "testimonial", kind: "written", quote: "Entraide formidable", display_name_snapshot: "Camille", consent: "1", status: "published" }
    expect(response).to have_http_status(:see_other)
    record = Testimonial.last
    expect(record.status).to eq("submitted")
    get account_community_path
    expect(response.body).to include("Entraide formidable")
    get testimonials_path
    expect(response.body).not_to include("Entraide formidable")
    delete destroy_user_session_path
    login admin
    get admin_community_index_path
    expect(response.body).to include("Entraide formidable", "Nouveau barème")
    post admin_community_index_path, params: { operation: "review_testimonial", record_id: record.id, decision: "published", reason: "Accord vérifié" }
    expect(response).to have_http_status(:see_other)
    get testimonials_path
    expect(response.body).to include("Entraide formidable")
    post account_community_path, params: { operation: "withdraw_testimonial", record_id: record.id }
    expect(response).to have_http_status(:forbidden)
    delete destroy_user_session_path
    login user
    post account_community_path, params: { operation: "withdraw_testimonial", record_id: record.id }
    get testimonials_path
    expect(response.body).not_to include("Entraide formidable")
    post account_community_path, params: { operation: "invalid" }
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "administre les quêtes sans laisser publier un barème à un administrateur délégué" do
    staff = create(:user, :admin)
    login staff
    get admin_community_index_path
    expect(response).to have_http_status(:forbidden)
    grant(staff, "community.manage")
    post admin_community_index_path, params: { operation: "quest", slug: "quartier", name: "Aider le quartier", description: "Décrire son action", reward_key: "share", recurrence: "monthly", reason: "Campagne" }
    expect(response).to have_http_status(:see_other)
    quest = Achievement.last
    record = Achievements.submit!(user: user, achievement: quest, evidence: "Action locale")
    get admin_community_index_path
    expect(response.body).to include("Action locale")
    post admin_community_index_path, params: { operation: "review_quest", record_id: record.id, decision: "approved", reason: "Vérifié" }
    expect(response).to have_http_status(:see_other)
    post admin_community_index_path, params: { operation: "quest_update", record_id: quest.id, name: "Quartier", description: "Agir", active: false, reason: "Pause" }
    expect(quest.reload.active).to be(false)
    post admin_community_index_path, params: { operation: "version", name: "Non", effective_at: 1.day.from_now }
    expect(response).to have_http_status(:forbidden)
    delete destroy_user_session_path
    login admin
    post admin_community_index_path, params: { operation: "version", name: "Demain", effective_at: 1.day.from_now, reason: "Barème" }
    expect(response).to have_http_status(:see_other)
    version = ChainRuleVersion.last
    %w[simulate publish].each do |action|
      post admin_community_index_path, params: { operation: action, record_id: version.id, reason: "Recette" }
      expect(response).to have_http_status(:see_other)
    end
    post admin_community_index_path, params: { operation: "rollback", record_id: version.id, name: "Retour", effective_at: 2.days.from_now, reason: "Retour" }
    expect(response).to have_http_status(:see_other)
    expect(ChainRuleVersion.last.status).to eq("draft")
    post admin_community_index_path, params: { operation: "unknown" }
    expect(response).to have_http_status(:unprocessable_content)
  end
end
