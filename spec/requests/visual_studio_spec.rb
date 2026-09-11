require "rails_helper"
RSpec.describe "Éditeur visuel", type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:document) { { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => [ { "id" => "hero", "template" => "home-0", "values" => {} } ] } } } } }
  let(:version) { Studio.change!(actor: admin, name: "Visuel", settings: document) }
  it "réserve les trois accès au super admin" do
    login create(:user, :admin)
    get visual_admin_site_path(version)
    expect(response).to have_http_status(:forbidden)
    post visual_preview_admin_site_path(version), params: { document: document.to_json }
    expect(response).to have_http_status(:forbidden)
    post visual_save_admin_site_path(version), params: { document: document.to_json, digest: version.digest }
    expect(response).to have_http_status(:forbidden)
  end
  it "rend un aperçu sans écrire et enregistre une copie avec des effets déclaratifs" do
    login admin
    get visual_admin_site_path(version)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Éditeur visuel", "Apparence et effets")
    edited = document.deep_dup
    edited["site"]["pages"]["home"]["blocks"][0].merge!("style" => { "size" => "large", "space" => "airy", "shape" => "organic", "animation" => "breathe" }, "elements" => { "text-4" => { "size" => "large", "animation" => "float" }, "image-0" => { "shape" => "rounded", "size" => "small" } })
    edited["tokens"] = { "deep" => "#123456", "motion" => "subtle" }
    expect { post visual_preview_admin_site_path(version), params: { document: edited.to_json, revision: "7" } }.not_to change(StudioVersion, :count)
    expect(response).to have_http_status(:ok)
    expect(response.headers["Cache-Control"]).to include("no-store")
    expect(response.headers["Content-Security-Policy"]).to include("frame-ancestors 'self'")
    expect(response.body).to include("studio-preview-revision", "site-breathe", "site-float", "site-section-hero")
    post visual_save_admin_site_path(version), params: { document: edited.to_json, digest: version.digest }
    expect(response).to have_http_status(:ok)
    saved = StudioVersion.last
    expect(saved.status).to eq("draft")
    expect(saved.site).to eq(edited["site"])
    expect(version.reload.site).to eq(document["site"])
    Studio.publish_from_review!(version: saved, actor: admin, digest: saved.digest, live_id: "")
    get root_path
    expect(response.body).to include("site-breathe", "site-float")
  end
  it "refuse les styles libres, scripts, références invalides et copies altérées" do
    login admin
    version
    bad = document.deep_dup
    bad["site"]["pages"]["home"]["blocks"][0]["elements"] = { "text-4" => { "animation" => "url(https://evil.test)" } }
    [ bad.to_json, "{} garbage", "[]", { "untrusted" => {} }.to_json ].each do |payload|
      expect { post visual_save_admin_site_path(version), params: { document: payload, digest: version.digest } }.not_to change(StudioVersion, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
    post visual_preview_admin_site_path(version), params: { document: bad.to_json }
    expect(response).to have_http_status(:unprocessable_content)
    post visual_save_admin_site_path(version), params: { document: document.to_json, digest: "incorrect" }
    expect(response).to have_http_status(:unprocessable_content)
  end
  it "prévisualise les pages de départ et refuse les pages inconnues" do
    login admin
    original = Studio.change!(actor: admin, name: "Départ", settings: {})
    %w[home don].each do |slug|
      post visual_preview_admin_site_path(original), params: { document: {}.to_json, page: slug }
      expect(response).to have_http_status(:ok)
    end
    post visual_preview_admin_site_path(original), params: { document: {}.to_json, page: "introuvable" }
    expect(response).to have_http_status(:not_found)
    get visual_admin_site_path(original, page: "introuvable")
    expect(response).to have_http_status(:not_found)
    post admin_site_index_path, params: { visual: "1", area: "kit" }
    expect(response).to redirect_to(visual_admin_site_path(StudioVersion.last, area: "kit"))
  end

  it "propose aussi des tailles compactes, une apparition et une respiration par élément" do
    login admin
    edited = document.deep_dup
    edited["site"]["pages"]["home"]["blocks"][0].merge!("style" => { "size" => "small", "space" => "compact", "shape" => "rounded", "animation" => "appear" }, "elements" => { "text-3" => { "size" => "small", "animation" => "breathe" }, "image-0" => { "size" => "large", "shape" => "organic" } })
    post visual_preview_admin_site_path(version), params: { document: edited.to_json }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("site-appear", "site-breathe", "padding-block:32px")
    post visual_save_admin_site_path(version), params: { document: "x" * (2.megabytes + 1), digest: version.digest }
    expect(response).to have_http_status(:unprocessable_content)
  end
end

RSpec.describe "Session de travail dans l’éditeur visuel", type: :request do
  it "permet d’ouvrir, prévisualiser et enregistrer avec une connexion ancienne encore valide" do
    admin = create(:user, :super_admin)
    version = Studio.change!(actor: admin, name: "Session", settings: {})
    login admin
    admin.login_sessions.last.update!(reauthenticated_at: 2.hours.ago)
    get visual_admin_site_path(version)
    expect(response).to have_http_status(:ok)
    expect { post visual_preview_admin_site_path(version), params: { document: {}.to_json } }.not_to change(StudioVersion, :count)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("studio-preview-revision")
    post visual_save_admin_site_path(version), params: { document: {}.to_json, digest: version.digest }
    expect(response).to have_http_status(:ok)
    saved = StudioVersion.last
    post publish_admin_site_path(saved), params: { digest: saved.digest, live_id: "" }
    expect(response).to have_http_status(:see_other)
    expect(saved.reload.status).to eq("published")
  end
end
