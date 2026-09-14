require "rails_helper"

RSpec.describe "Accès inclus dans le rôle admin", type: :request do
  it "ouvre le panneau et la modération des annonces sans permission individuelle" do
    admin = create(:user, :admin)
    listing = create(:listing)
    login admin
    get admin_root_path
    expect(response.body).to include("Gérer les annonces")
    expect(response.body).not_to include("Gestion du site", "Propositions éditoriales")
    get admin_workbench_index_path(kind: "annonces")
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(listing.title)
    patch admin_workbench_path(listing.id, kind: "annonces"), params: { status: "paused", reason: "Abus examiné par un admin" }
    expect(response).to have_http_status(:see_other)
    expect(listing.reload.moderation_hold).to be(true)
  end

  it "refuse les outils du site même avec toutes les anciennes permissions éditoriales" do
    admin = create(:user, :admin)
    User::SITE_SUPER_ADMIN_PERMISSIONS.each { |permission| create(:admin_permission_grant, user: admin, permission: permission) }
    login admin
    get admin_root_path
    expect(response.body).not_to include("Gestion du site", "Propositions éditoriales", "Kit UI/UX")
    paths = [ admin_site_index_path, admin_studio_index_path ] + %w[categories restrictions contenus].map { |kind| admin_workbench_index_path(kind: kind) }
    paths.each do |path|
      get path
      expect(response).to have_http_status(:forbidden), path
      post path, params: { reason: "Tentative" }
      expect(response).to have_http_status(:forbidden), path
    end
    category = create(:category)
    get admin_workbench_path(category.id, kind: "categories")
    expect(response).to have_http_status(:forbidden)
    patch admin_workbench_path(category.id, kind: "categories"), params: { record: { name: "Interdit" }, reason: "Tentative" }
    expect(response).to have_http_status(:forbidden)
    expect(category.reload.name).not_to eq("Interdit")
    admin.update!(status: "suspended")
    expect(admin.permission?("listings.moderate")).to be(false)
  end

  it "conserve la gestion du site pour le super admin" do
    login create(:user, :super_admin)
    get admin_root_path
    expect(response.body).to include("Gestion du site")
    [ admin_site_index_path, admin_studio_index_path, admin_workbench_index_path(kind: "categories") ].each do |path|
      get path
      expect(response).to have_http_status(:ok), path
    end
  end
end
