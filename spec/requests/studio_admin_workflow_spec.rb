require "rails_helper"
RSpec.describe "Studio admin guidé", type: :request do
  let(:admin) { create(:user, :super_admin) }
  it "présente une seule entrée de gestion, adaptée au rôle" do
    login admin
    get root_path
    header = Nokogiri::HTML(response.body).at_css("header")
    expect(header.css("a").map(&:text)).to include("Studio admin")
    expect(header.text).not_to include("Super-administration", "Mon site")
    get super_admin_root_path
    expect(response).to redirect_to(admin_root_path)
    follow_redirect!
    expect(response.body).to include("Gérer les pages", "Ouvrir le kit UI/UX")
    delete destroy_user_session_path
    login create(:user, :admin)
    get admin_root_path
    expect(response.body).to include("Studio admin")
    expect(response.body).not_to include("Personnalisation", "Gérer les pages")
  end

  it "crée une page à partir de son nom et publie seulement après ajout de contenu" do
    login admin
    get new_page_admin_site_index_path
    expect(response.body).to include("Nom de la page")
    post admin_site_index_path, params: { operation: "create_page", title: "Notre équipe" }
    version = StudioVersion.last
    block = version.site.dig("pages", "notre-equipe", "blocks", 0)
    expect(response).to redirect_to(edit_admin_site_path(version, page: "notre-equipe", section: block["id"]))
    follow_redirect!
    expect(response.body).to include("Enregistrer et voir le résultat")
    get review_admin_site_path(version, page: "notre-equipe")
    expect(response.body).to include("Ajoutez du contenu")
    post publish_admin_site_path(version), params: { digest: version.digest, live_id: "" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(version.reload.status).to eq("draft")
    patch admin_site_path(version), params: { operation: "page", page: "notre-equipe", block_id: block["id"], block_action: "save", after_save: "review", values: { title: "Notre équipe", body: "Nous accompagnons les voisins.", label: "", url: "" } }
    saved = StudioVersion.last
    expect(response).to redirect_to(review_admin_site_path(saved, page: "notre-equipe"))
    follow_redirect!
    expect(response.body).to include("Téléphone", "Tablette", "Ordinateur", "Mettre en ligne")
    expect(response.body).not_to include("Motif de validation", "375 px")
    post publish_admin_site_path(saved), params: { digest: saved.digest, live_id: "" }
    expect(response).to have_http_status(:see_other)
    expect(saved.reload.status).to eq("published")
    get site_page_path("notre-equipe")
    expect(response.body).to include("Nous accompagnons les voisins.")
    expect(saved.settings.dig("site", "pages", "notre-equipe", "blocks", 0, "values")).not_to have_key("url")
    post admin_site_index_path, params: { operation: "create_page", title: "Notre équipe" }
    expect(StudioVersion.last.site["pages"]).to have_key("notre-equipe-2")
  end

  it "protège l’aperçu et refuse les publications obsolètes ou altérées" do
    first = Studio.change!(actor: admin, settings: {}, name: "Essai")
    login create(:user, :admin)
    get review_admin_site_path(first)
    expect(response).to have_http_status(:forbidden)
    post publish_admin_site_path(first), params: { digest: first.digest }
    expect(response).to have_http_status(:forbidden)
    delete destroy_user_session_path
    login admin
    post publish_admin_site_path(first), params: { digest: "incorrect" }
    expect(response).to have_http_status(:unprocessable_content)
    second = Studio.change!(actor: admin, settings: {}, name: "Autre modification")
    Studio.publish_from_review!(version: second, actor: admin, digest: second.digest, live_id: "")
    expect { post publish_admin_site_path(first), params: { digest: first.digest, live_id: "" } }.not_to change(AuditLog, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(first.reload.status).to eq("draft")
    get admin_site_index_path
    expect(response.body).to include("Consulter cette sauvegarde")
  end

  it "conserve la publication et les audits atomiques" do
    version = Studio.change!(actor: admin, settings: {}, name: "Essai")
    allow(Studio).to receive(:transition!).and_call_original
    allow(Studio).to receive(:transition!).with(version: version, actor: admin, action: "publish", reason: anything).and_raise(Exchanges::Invalid, "Publication interrompue")
    expect { Studio.publish_from_review!(version: version, actor: admin, digest: version.digest, live_id: "") }.to raise_error(Exchanges::Invalid)
    expect(version.reload.status).to eq("draft")
    expect(version.validated_digest).to be_nil
    expect(AuditLog.where(target: version).pluck(:action)).to eq([ "studio.draft" ])
  end
end
