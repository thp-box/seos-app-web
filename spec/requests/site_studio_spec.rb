require "rails_helper"
RSpec.describe "Composition du site", type: :request do
  let(:admin) { create(:user, :super_admin) }
  def publish(version)
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette du site") }
  end
  def draft
    Studio.change!(actor: admin, settings: {}, name: "Site de recette")
  end
  it "réserve le compositeur et le kit au super admin" do
    login create(:user)
    get admin_site_index_path
    expect(response).to have_http_status(:forbidden)
    get kit_admin_site_path(draft)
    expect(response).to have_http_status(:forbidden)
  end
  it "expose les formulaires, écrans du kit et images locales" do
    login admin
    get admin_site_index_path
    expect(response).to have_http_status(:ok)
    post admin_site_index_path, params: { name: "Site" }
    version = StudioVersion.last
    %w[pages header footer kit images].each do |area|
      get edit_admin_site_path(version, area: area)
      expect(response).to have_http_status(:ok), response.body
    end
    SiteDesign.reference["kit"].each_key do |screen|
      get kit_admin_site_path(version, page: screen)
      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(response.body).not_to include('src="https://images.unsplash.com')
    end
  end
  it "ajoute, modifie, déplace, masque, duplique et supprime des sections sans muter la source" do
    login admin
    original = draft
    patch admin_site_path(original), params: { operation: "page", page: "home", template: "home-0" }
    expect(response).to have_http_status(:see_other)
    version = StudioVersion.last
    block = version.site.dig("pages", "home", "blocks").first
    expect(original.reload.site).to eq({})
    patch admin_site_path(version), params: { operation: "page", page: "home", block_id: block["id"], block_action: "save", hidden: "1", values: { "text-0" => "Notre communauté", "link-0" => "/contact" } }
    version = StudioVersion.last
    expect(version.site.dig("pages", "home", "blocks", 0, "hidden")).to be(true)
    %w[duplicate down up remove].each do |action|
      patch admin_site_path(version), params: { operation: "page", page: "home", block_id: block["id"], block_action: action }
      expect(response).to have_http_status(:see_other)
      version = StudioVersion.last
    end
    expect(version.site.dig("pages", "home", "blocks").size).to eq(1)
    get edit_admin_site_path(version)
    expect(response).to have_http_status(:ok)
  end
  it "publie une page et le chrome, puis restaure une zone sans perdre les autres" do
    login admin
    version = draft
    patch admin_site_path(version), params: { operation: "page", page: "notre-association", title: "Notre association", template: "text" }
    version = StudioVersion.last
    patch admin_site_path(version), params: { operation: "chrome", area: "footer", chrome: { title: "Ensemble ici", description: "À Paris", logo: "seos-logo.png", alt: "Notre logo" }, links: { "0" => { label: "Association", url: "/pages/notre-association" }, "1" => { label: "", url: "" } } }
    expect(response).to have_http_status(:see_other)
    version = StudioVersion.last
    get preview_admin_studio_path(version, page: "notre-association", canvas: "1")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Notre association", "Ensemble ici")
    get site_page_path("notre-association")
    expect(response).to have_http_status(:not_found)
    publish(version)
    get site_page_path("notre-association")
    expect(response.body).to include("Ensemble ici", "Notre association")
    get sitemap_path
    expect(response.body).to include(site_page_url("notre-association"))
    patch admin_site_path(version), params: { operation: "reset", area: "footer" }
    reset = StudioVersion.last
    expect(reset.chrome("footer")["title"]).to eq(SiteDesign::CHROME["footer"]["title"])
    expect(reset.site["pages"]).to eq(version.site["pages"])
    expect(version.reload.status).to eq("published")
    patch admin_site_path(reset), params: { operation: "reset", area: "pages", page: "notre-association" }
    expect(StudioVersion.last.site["pages"]).to eq({})
  end
  it "publie les sections de maquette avec valeurs échappées et liens réels" do
    values = { "text-0" => '<script>alert("x")</script>' }
    blocks = [ { "id" => "hero", "template" => "home-0", "values" => values } ]
    version = Studio.change!(actor: admin, name: "Maquette", settings: { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => blocks } } } })
    publish(version)
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('&lt;script&gt;', '/compte/annonces/new')
    expect(response.body).not_to include('<script>alert', '/users/sign_up')
  end
  it "refuse les liens exécutables, les templates inconnus et les documents malformés" do
    base = { "id" => "abc", "template" => "text", "values" => { "url" => "javascript:alert(1)" } }
    expect(SiteDesign.valid_block?(base)).to be(false)
    %w[//evil.test /\\evil.test https://user@evil.test http://evil.test].each do |url|
      expect(SiteDesign.safe_url?(url)).to be_falsey
    end
    expect(SiteDesign.valid?({ "pages" => [] })).to be(false)
    expect(SiteDesign.valid_block?(base.merge("template" => "../../secret"))).to be(false)
    expect(SiteDesign.valid_block?(base.merge("values" => { "extra" => "value" }))).to be(false)
    login admin
    expect { patch admin_site_path(draft), params: { operation: "page", page: "home", template: "bad" } }.to change(StudioVersion, :count).by(1)
    expect(response).to have_http_status(:unprocessable_content)
  end
  it "conserve les images des brouillons privées et révoque l'accès après masquage" do
    asset = StudioAsset.create!(author: admin)
    SafeImage.attach!(asset.image, Rack::Test::UploadedFile.new(Rails.root.join("app/assets/images/seos-logo.png"), "image/png"))
    block = { "id" => "hero", "template" => "home-0", "values" => { "image-0" => "asset:#{asset.id}", "alt-0" => "L’équipe" } }
    settings = { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => [ block ] } } } }
    version = Studio.change!(actor: admin, name: "Image", settings: settings)
    get media_path(asset.image.attachment)
    expect(response).to have_http_status(:not_found)
    publish(version)
    get media_path(asset.image.attachment)
    expect(response).to have_http_status(:ok)
    settings["site"]["pages"]["home"]["blocks"][0]["hidden"] = true
    hidden = Studio.change!(actor: admin, name: "Masquage", settings: settings, source: version)
    publish(hidden)
    get media_path(asset.image.attachment)
    expect(response).to have_http_status(:not_found)
  end
  it "applique et réinitialise le kit sans modifier les pages" do
    login admin
    version = draft
    patch admin_site_path(version), params: { operation: "tokens", area: "kit", tokens: { "wave-speed" => "12s", "wave-shape" => "diagonal", "motion" => "subtle", "section-space" => "72px", "button-radius" => "26px", "card-radius" => "16px", "wave-height" => "135px", "deep" => "#004961", "font-heading" => "DM Sans, sans-serif" } }
    version = StudioVersion.last
    expect(version.css).to include("seos-wave", "12s", "polygon", "prefers-reduced-motion")
    patch admin_site_path(version), params: { operation: "reset", area: "kit" }
    expect(StudioVersion.last.tokens).to eq({})
    expect(version.reload.tokens["wave-speed"]).to eq("12s")
  end
end

RSpec.describe "Régressions du kit de maquette", type: :request do
  let(:admin) { create(:user, :super_admin) }
  it "rend toutes les sections sans reprendre les données personnelles de démonstration" do
    blocks = SiteDesign.templates.keys.map.with_index { |key, i| { "id" => "section-#{i}", "template" => key, "values" => {}, "separator" => "wave_single", "placement" => i.even? ? "top" : "bottom" } }
    version = Studio.change!(actor: admin, name: "Toutes les sections", settings: { "site" => { "pages" => { "home" => { "title" => "Accueil", "blocks" => blocks } } } })
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette") }
    get root_path
    expect(response).to have_http_status(:ok)
    expect(Nokogiri::HTML(response.body).css("h1").size).to eq(1)
    expect(response.body).to include("Aucune annonce", "témoignages publiés")
    expect(response.body).not_to include("Amina B.", "63 échanges", "40 Points Services en circulation")
  end
  it "importe un contenu éditorial existant avec un identifiant stable" do
    content = ContentVersion.create!(author: admin, kind: "page", slug: "don", title: "Donner", summary: "Librement", body: "Aucune contrepartie", version: 1, published_at: Time.current)
    first = SiteDesign.default_page("don")
    expect(first).to eq(SiteDesign.default_page("don"))
    version = Studio.change!(actor: admin, name: "Page", settings: {})
    login admin
    patch admin_site_path(version), params: { operation: "page", page: "don", block_id: first["blocks"].first["id"], block_action: "save", values: { title: "Un nouveau titre", body: content.body }, separator: "wave_double", placement: "top" }
    expect(response).to have_http_status(:see_other)
    version = StudioVersion.last
    expect(version.site.dig("pages", "don", "blocks", 0, "values", "title")).to eq("Un nouveau titre")
    get preview_admin_studio_path(version, page: "don", canvas: "1")
    expect(response.body).to include("Un nouveau titre", "wave_double")
  end
  it "rejette les opérations et destinations non prévues sans écrire de brouillon" do
    version = Studio.change!(actor: admin, name: "Page", settings: {})
    login admin
    invalid = [ { operation: "nope" }, { operation: "reset", area: "nope" }, { operation: "chrome", area: "nope" }, { operation: "page", page: "../" }, { operation: "page", page: "home", block_id: "absent", block_action: "save" }, { operation: "chrome", area: "header", chrome: { logo: "https://evil.test/image.png", alt: "Logo" } } ]
    invalid.each do |attributes|
      expect { patch admin_site_path(version), params: attributes }.not_to change(StudioVersion, :count)
      expect(response).to have_http_status(:unprocessable_content)
    end
    expect { Studio.change!(actor: create(:user, :admin), name: "Effacement", settings: { "site" => {} }, source: version) }.to raise_error(Pundit::NotAuthorizedError)
    expect(SiteDesign.safe_url?("https://example.org/")).to be(true)
    expect(SiteDesign.safe_url?("https://[malformed")).to be(false)
    expect(SiteDesign.safe_url?("#presentation")).to be(true)
    expect(SiteDesign.valid?({ "header" => { "logo" => "seos-logo.png" } })).to be(false)
    expect(SiteDesign.valid?({ "header" => { "bad" => "value" } })).to be(false)
    expect(SiteDesign.valid?({ "pages" => { "bad slug" => {} } })).to be(false)
  end
end

RSpec.describe "Sections alimentées par les données publiques", type: :request do
  it "utilise les annonces éligibles et les témoignages consentis" do
    listing = create(:listing, title: "Atelier partagé", address_line: "14 rue Secrète")
    listing.photos.attach(io: File.open(Rails.root.join("app/assets/images/seos-logo.png")), filename: "photo.png", content_type: "image/png")
    hidden = create(:listing, title: "Annonce brouillon invisible", status: "draft")
    testimonial = Testimonial.create!(user: listing.user, kind: "written", status: "published", quote: "Une expérience partagée", display_name_snapshot: "Camille", public_location_snapshot: "Lyon", consent_version: Testimonial::CONSENT_VERSION, consented_at: Time.current)
    admin = create(:user, :super_admin)
    blocks = %w[home-2 home-3 home-6].map { |template| { "id" => template, "template" => template, "values" => {} } }
    version = Studio.change!(actor: admin, name: "Communauté", settings: { "site" => { "pages" => { "home" => { "title" => "Notre communauté", "blocks" => blocks } } } })
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Recette") }
    get root_path
    expect(response.body).to include(listing.title, listing.category.name, testimonial.quote)
    expect(response.body).not_to include(hidden.title, listing.user.email, "14 rue Secrète")
    testimonial.update!(removed_at: Time.current)
    listing.user.update!(status: "suspended")
    get root_path
    expect(response.body).not_to include(listing.title, testimonial.quote)
  end
end
