require "rails_helper"

RSpec.describe "Démonstration en production" do
  it "charge les exemples deux fois sans doublons ni écrasement des comptes ou de l’accueil" do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("production"))
    load Rails.root.join("db/seeds.rb")
    expect(User.where(email: %w[membre@seos.test superadmin@seos.test association@seos.test admin@seos.test partenaire@seos.test]).count).to eq(5)
    expect(Listing.where(slug: %w[demo-bricolage demo-numerique demo-jardin]).count).to eq(3)
    expect(VolunteerMission.where(slug: %w[eco-lieu-demo education-demo refuge-demo], status: "published").count).to eq(3)
    expect(Listing.find_by!(slug: "demo-bricolage").photos).to be_attached
    expect(StudioVersion.current.site.dig("pages", "home")).to be_present
    admin = User.find_by!(email: "superadmin@seos.test")
    admin.update!(password: "MotDePasseModifie!2026")
    models = [ User, Profile, Listing, Organization, OrganizationMembership, VolunteerMission, Partnership, StudioVersion, ContentVersion, ActiveStorage::Attachment ]
    counts = models.map(&:count)
    home = StudioVersion.current.id
    load Rails.root.join("db/seeds.rb")
    expect(models.map(&:count)).to eq(counts)
    expect(StudioVersion.current.id).to eq(home)
    expect(admin.reload.valid_password?("MotDePasseModifie!2026")).to be(true)
  end
end
