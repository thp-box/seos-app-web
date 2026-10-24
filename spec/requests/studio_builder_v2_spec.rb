require "rails_helper"

RSpec.describe "Studio V2", type: :request do
  it "réserve le constructeur visuel au super-admin et enregistre un brouillon sûr" do
    admin = create(:user, :super_admin)
    source = Studio.change!(
      actor: admin,
      name: "Source Studio V2",
      settings: { "site" => { "pages" => { "home" => SiteDesign.home_page } } }
    )

    login create(:user)
    get builder_admin_site_path(source)
    expect(response).to have_http_status(:forbidden)

    delete destroy_user_session_path
    login admin
    get builder_admin_site_path(source)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Studio V2", "Édition directe", "Compositions", "data-studio-styles")

    document = source.settings.deep_dup
    document["tokens"] = source.tokens.merge("wave-angle" => "7deg", "wave-speed" => "11s", "wave-amplitude" => "16px", "wave-roundness" => "73%")
    document.dig("site", "pages", "home")["canvas"] = {
      "version" => 1,
      "html" => '<main><h1 style="font-weight:700">Un titre construit librement</h1><script>alert(1)</script></main>',
      "css" => "h1{font-family:serif}"
    }
    post builder_save_admin_site_path(source), params: { document: document.to_json, digest: source.digest, page: "home" }, as: :json

    expect(response).to have_http_status(:ok)
    result = response.parsed_body
    draft = StudioVersion.find(result.fetch("url").match(%r{/admin/site/(\d+)/builder})[1])
    expect(draft.tokens).to include("wave-angle" => "7deg", "wave-speed" => "11s", "wave-amplitude" => "16px", "wave-roundness" => "73%")
    expect(draft.site.dig("pages", "home", "canvas", "html")).to include("Un titre construit librement", "font-weight:700")
    expect(draft.site.dig("pages", "home", "canvas", "html")).not_to include("script", "alert")
    expect(draft.site.dig("pages", "home", "canvas", "css")).to eq("h1{font-family:serif}")
    expect(draft.css).to include(".site-wave-layers", "rotate:var(--wave-angle)", "animation:seos-wave", "border-radius:var(--wave-roundness)")
    expect(result.fetch("review")).to eq(review_admin_site_path(draft))

    post visual_preview_admin_site_path(source), params: { document: draft.settings.to_json, page: "home", revision: "canvas" }
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Un titre construit librement", "h1{font-family:serif}")
    expect(response.body).not_to include("alert(1)")
  end

  it "rejette les angles de vague hors des limites autorisées" do
    admin = create(:user, :super_admin)
    source = Studio.change!(actor: admin, name: "Source", settings: {})
    login admin
    document = source.settings.deep_dup
    document["tokens"] = { "wave-angle" => "999deg" }

    post builder_save_admin_site_path(source), params: { document: document.to_json, digest: source.digest, page: "home" }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body.fetch("error")).to include("wave-angle")
  end
end
