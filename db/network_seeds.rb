%w[voyage_enabled partnerships_enabled].each do |key|
  FeatureFlag.find_or_create_by!(key: key) { |flag| flag.enabled = true }
end
if Rails.env.development?
  organization = Organization.find_by(slug: "entraide-solidaire-demo")
  if organization
    organization.update!(description: "Une association de démonstration pour préparer des actions solidaires.", public_location: "Lyon", legal_name: "Association de démonstration SEOS", legal_email: "association@seos.test", registration_number: "DEMO-NON-OFFICIEL") if organization.description.blank?
    organization.volunteer_missions.find_or_create_by!(slug: "jardin-solidaire-demo") do |mission|
      mission.assign_attributes(title: "Participer au jardin solidaire", description: "Aider une équipe associative au jardin et partager les repas.", country_code: "FR", public_location: "Lyon", starts_on: Date.current + 14, ends_on: Date.current + 30, minimum_stay_days: 2, volunteer_capacity: 2, accommodation: "Chambre partagée", meals: "Repas préparés ensemble", languages: "Français", daily_contribution_cents: 0)
    end
    organization.partnerships.find_or_create_by!(slug: "partenariat-entraide-demo") do |record|
      record.assign_attributes(public_title: "Un partenariat pour l’entraide", public_description: "Présentation de démonstration à examiner avant publication.", starts_on: Date.current, ends_on: Date.current + 90)
    end
  end
end
