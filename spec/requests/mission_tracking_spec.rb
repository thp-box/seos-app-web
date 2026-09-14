require "rails_helper"

RSpec.describe "Suivi des missions", type: :request do
  it "pagine 200 missions, filtre et modifie une mission hors de la première page" do
    owner = create(:profile).user
    organization = organization_space(owner: owner)
    records = 200.times.map do |index|
      organization.volunteer_missions.create!(title: "Mission %03d" % index, public_location: index.even? ? "Lyon" : "Paris")
    end
    other = organization_space
    foreign = other.volunteer_missions.create!(title: "Mission extérieure")
    login owner
    get account_organization_path(organization), params: { tab: "missions", mission_sort: "title" }
    document = Nokogiri::HTML(response.body)
    expect(document.css(".mission-tracking-table tbody tr").length).to eq(15)
    expect(response.body).to include("200 résultats", "Page 1 sur 14")
    expect(document.css(".mission-tracking-table").text).not_to include("Mission 199", foreign.title)

    get account_organization_path(organization), params: { tab: "missions", mission_sort: "title", mission_page: 14 }
    expect(Nokogiri::HTML(response.body).css(".mission-tracking-table tbody tr").length).to eq(5)
    expect(response.body).to include("Mission 199")
    patch account_organization_path(organization), params: { operation: "mission", record_id: records.last.id, mission_page: 14, mission_sort: "title", mission: { title: "Mission 199 corrigée" } }
    expect(response).to have_http_status(:see_other)
    expect(records.last.reload.title).to eq("Mission 199 corrigée")
    expect(response.location).to include("mission_page=14")

    get account_organization_path(organization), params: { tab: "missions", mission_search: "Paris", mission_status: "draft", mission_page: 999 }
    expect(response.body).to include("100 résultats", "Page 7 sur 7")
    expect(Nokogiri::HTML(response.body).css(".mission-tracking-table tbody tr").length).to eq(10)
    get account_organization_path(organization), params: { mission_id: foreign.id }
    expect(response).to have_http_status(:not_found)
  end
  it "conserve les saisies lorsqu’un brouillon est invalide" do
    owner = create(:profile).user
    organization = organization_space(owner: owner)
    login owner
    expect {
      patch account_organization_path(organization), params: { operation: "mission", mission: { title: "Le jardin de demain", country_code: "France" } }
    }.not_to change(VolunteerMission, :count)
    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Le brouillon n’a pas été enregistré", 'value="Le jardin de demain"', 'value="France"')
  end

  it "filtre les candidatures sans ouvrir celles d’une autre organisation" do
    owner = create(:profile).user
    organization = organization_space(owner: owner)
    selected = world_mission(organization: organization, title: "Mission sélectionnée")
    excluded = world_mission(organization: organization, title: "Autre mission")
    foreign = world_mission(title: "Mission privée étrangère")
    [ selected, excluded, foreign ].each do |mission|
      mission.mission_applications.create!(user: create(:profile).user, message: "Je souhaite participer", starts_on: mission.starts_on, ends_on: mission.ends_on)
    end
    login owner
    get account_mission_applications_path(mission_id: selected.id)
    expect(response.body).to include(selected.title)
    expect(response.body).not_to include(excluded.title, foreign.title)
    get account_mission_applications_path(mission_id: foreign.id)
    expect(response.body).not_to include(foreign.title)
    expect(response.body).to include("Aucune candidature")
  end
end
