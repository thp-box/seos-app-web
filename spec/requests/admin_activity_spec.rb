require "rails_helper"

RSpec.describe "Indicateurs du tableau de bord", type: :request do
  it "donne aux admins les agrégats sans données personnelles et garde les compléments de supervision au super admin" do
    admin = create(:user, :admin)
    create(:profile, display_name: "NOM NON EXPOSE", phone: "0612345678", address_line: "ADRESSE PRIVEE")
    login admin
    get admin_root_path(period: 7)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Inscriptions sur la période", "Premières publications", "7 jours précédents")
    expect(response.body).not_to include("NOM NON EXPOSE", "0612345678", "ADRESSE PRIVEE", "Organisations à vérifier")
    get admin_root_path(period: 90)
    expect(response.body).to include("90 jours précédents")
    delete destroy_user_session_path
    login create(:user, :super_admin)
    get admin_root_path
    expect(response.body).to include("Organisations à vérifier", "Signalements ouverts")
  end
end
