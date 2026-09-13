# Local demonstration only: never publish fictitious missions in production.
if Rails.env.development?
  association = Organization.find_by!(slug: "entraide-solidaire-demo")
  admin = User.find_by!(email: "superadmin@seos.test")
  [
    [ "eco-lieu-demo", "Participer à un éco-lieu", "Jardinage, cuisine collective et accueil.", "FR", "Ardèche", 10, "Chambre partagée", "Repas inclus", "photo-1416879595882-3373a0480b5be3d794ff.jpg" ],
    [ "education-demo", "Soutien à un projet éducatif", "Animation et aide aux devoirs avec l’équipe associative.", "BE", "Belgique", 0, "Hébergement non inclus", "Repas inclus", "photo-1488521787991-ed7bbaae773c85b4eae3.jpg" ],
    [ "refuge-demo", "Aider dans un refuge", "Accueil, entretien et cuisine dans un refuge de montagne.", "CH", "Suisse", 15, "Hébergement inclus", "Repas préparés ensemble", "photo-1500530855697-b586d89ba3ee69246eaa.jpg" ]
  ].each do |slug, title, description, country, region, points, accommodation, meals, photo|
    mission = association.volunteer_missions.find_or_initialize_by(slug: slug)
    if mission.new_record?
      mission.assign_attributes(title: title, description: description, country_code: country, region: region, public_location: region, daily_contribution_points: points, starts_on: Date.current + 7, ends_on: Date.current + 180, minimum_stay_days: 2, volunteer_capacity: 4, accommodation: accommodation, meals: meals, languages: "Français", status: "published", published_by: admin, published_at: Time.current)
      mission.save!(context: :publication)
    end
    unless mission.photos.attached?
      File.open(Rails.root.join("app/assets/images/maquette", photo)) do |file|
        mission.photos.attach(io: file, filename: photo, content_type: "image/jpeg")
      end
    end
  end
end
