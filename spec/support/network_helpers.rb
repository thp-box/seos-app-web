module NetworkHelpers
  def organization_space(owner: create(:profile).user, **attributes)
    organization = create(:organization, **{ description: "Association du jardin partagé", legal_name: "Association légale", registration_number: "RNA-W123456789", legal_email: "legal@example.test", published_at: Time.current }.merge(attributes))
    create(:organization_membership, organization: organization, user: owner, role: :owner)
    organization
  end
  def mission_attributes
    { title: "Jardin solidaire", description: "Aider au jardin et partager la vie locale", country_code: "FR", public_location: "Lyon", private_address: "Adresse réservée aux bénévoles acceptés", starts_on: Date.current + 2, ends_on: Date.current + 20, languages: "Français", accommodation: "Chambre partagée", meals: "Repas végétariens", daily_contribution_cents: 500, minimum_stay_days: 2 }
  end
  def world_mission(organization: organization_space, **attributes)
    VolunteerMission.create!({ organization: organization, status: "published", published_at: Time.current }.merge(mission_attributes).merge(attributes))
  end
  def partnership_attributes
    { public_title: "Entraide ensemble", public_description: "Un partenariat local", starts_on: Date.current, ends_on: Date.current + 20, cta_url: "https://example.org/projet", cta_label: "Découvrir le projet" }
  end
end
RSpec.configure { |config| config.include NetworkHelpers }
