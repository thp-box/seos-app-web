require "rails_helper"

RSpec.describe "Refonte des espaces", type: :request do
  it "remplace les fiches partenaires par une page publique éditée par le super-admin" do
    get partnership_page_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Nos partenaires")
    get "/partenaires/ancienne-fiche"
    expect(response).to have_http_status(:not_found)

    admin = create(:user, :super_admin)
    login admin
    patch admin_partnership_page_path, params: { partnership_page: { title: "Ils avancent avec SEOS", introduction: "Un réseau engagé.", body: "Présentation commune." } }
    expect(response).to redirect_to(edit_admin_partnership_page_path)
    get partnership_page_path
    expect(response.body).to include("Ils avancent avec SEOS", "Présentation commune.")
  end

  it "permet au super-admin de gérer des cartes partenaires avec logo et lien" do
    admin = create(:user, :super_admin)
    login admin
    logo = Rack::Test::UploadedFile.new(Rails.root.join("app/assets/images/seos-logo.png"), "image/png")

    post admin_partners_path, params: { partner_entry: { title: "Collectif Exemple", description: "Un partenaire engagé.", website_url: "https://example.org", position: 1, logo: logo } }
    expect(response).to redirect_to(edit_admin_partnership_page_path(anchor: "partners"))
    partner = PartnerEntry.last
    expect(partner.logo).to be_attached

    get partnership_page_path
    expect(response.body).to include("Collectif Exemple", "Un partenaire engagé.", "https://example.org")

    patch admin_partner_path(partner), params: { partner_entry: { title: "Collectif Actualisé", description: partner.description, website_url: partner.website_url, position: 2 } }
    expect(partner.reload).to have_attributes(title: "Collectif Actualisé", position: 2)
    delete admin_partner_path(partner)
    expect(PartnerEntry.where(id: partner.id)).not_to exist
  end

  it "sépare quêtes, preuves et chaînes dans des onglets adressables" do
    point_rules
    load Rails.root.join("db/community_seeds.rb")
    login create(:user, :super_admin)

    get admin_community_index_path(tab: "quests")
    expect(response.body).to include("Catalogue des quêtes")
    expect(response.body).not_to include("Chaînes et médiation")
    get admin_community_index_path(tab: "chains")
    expect(response.body).to include("Chaînes et médiation")
    expect(response.body).not_to include("Catalogue des quêtes")
  end

  it "pagine, filtre et n’ouvre qu’un seul éditeur de quête à la fois" do
    30.times do |index|
      Achievement.create!(
        slug: "quete-catalogue-#{index}",
        name: index == 27 ? "Quête introuvable ailleurs" : "Quête catalogue #{index}",
        description: "Une preuve claire pour tester le catalogue numéro #{index}.",
        event_name: "manual",
        reward_key: "welcome",
        recurrence: "once",
        active: index % 3 != 0
      )
    end
    login create(:user, :super_admin)

    get admin_community_index_path(tab: "quests")
    document = Nokogiri::HTML(response.body)
    expect(document.css(".quest-library-card").size).to eq(24)
    expect(response.body).to include("Page <strong>1</strong> sur <strong>2</strong>")
    expect(document.css('input[name="operation"][value="quest_update"]')).to be_empty

    selected = Achievement.find_by!(slug: "quete-catalogue-2")
    get admin_community_index_path(tab: "quests", edit_quest: selected.id)
    document = Nokogiri::HTML(response.body)
    expect(document.css('input[name="operation"][value="quest_update"]').size).to eq(1)
    expect(document.at_css("#quest-editor-title").text).to include(selected.name)

    get admin_community_index_path(tab: "quests", quest_q: "introuvable ailleurs")
    document = Nokogiri::HTML(response.body)
    expect(document.css(".quest-library-card").size).to eq(1)
    expect(response.body).to include("Quête introuvable ailleurs")

    get admin_community_index_path(tab: "quests", quest_status: "archived")
    expect(Nokogiri::HTML(response.body).css(".quest-library-card").size).to eq(10)
  end

  it "réserve la page partenaires et l’éditeur visuel au super-admin" do
    login create(:user)
    get edit_admin_partnership_page_path
    expect(response).to have_http_status(:forbidden)

    delete destroy_user_session_path
    login create(:user, :super_admin)
    get admin_site_index_path
    expect(response).to have_http_status(:see_other)
    expect(response.location).to include("/admin/site/", "/visual")
  end

  it "affiche le contrôle de visibilité sur les mots de passe" do
    get new_user_session_path
    expect(response).to have_http_status(:ok)
    document = Nokogiri::HTML(response.body)
    expect(document.at_css('[data-controller="password-visibility"] input[type="password"]')).to be_present
    expect(document.at_css('button[aria-label="Afficher le mot de passe"]')).to be_present
  end

  it "ne rend plus les anciennes sections de soutien financier" do
    get root_path
    expect(response.body).not_to include("Soutenir SEOS", "soutien matériel")
    expect(SiteDesign.editable_templates.keys).not_to include("home-10", "community-support")
  end

  it "montre le suivi des chaînes sur le profil et permet leur mise en avant" do
    point_rules
    load Rails.root.join("db/community_seeds.rb")
    profile = create(:profile)
    chain = Chains.create!(actor: profile.user, name: "La chaîne du quartier")
    chain.update!(featured_on_home: true)

    get profile_path(profile)
    expect(response.body).to include("La chaîne du quartier", "Le parcours complet")
    get root_path
    expect(response.body).to include("La chaîne du quartier", "L’entraide en mouvement")

    login create(:user, :super_admin)
    patch admin_user_path(profile.user), params: { operation: "feature_chain", chain_id: chain.id, featured: "0" }
    expect(response).to redirect_to(admin_user_path(profile.user))
    expect(chain.reload).not_to be_featured_on_home
  end
end
