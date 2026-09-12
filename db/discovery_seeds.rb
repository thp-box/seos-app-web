# Required reference data can be loaded in every environment without demo identities.
{
  "reliability" => "Fiabilité", "task_quality" => "Qualité du service", "respect_safety" => "Respect et sécurité",
  "communication" => "Communication", "punctuality" => "Ponctualité"
}.each do |key, label|
  ReviewCriterion.find_or_create_by!(key: key) { |criterion| criterion.label = label }
end
FeatureFlag.find_or_create_by!(key: "public_map_enabled")

if Rails.env.development?
  ApplicationRecord.transaction do
    categories = { "bricolage" => "Bricolage", "jardinage" => "Jardinage", "informatique" => "Informatique", "apprentissage" => "Apprentissage" }.map do |slug, name|
      Category.find_or_create_by!(slug: slug) { |category| category.name = name }
    end
    member = User.find_by!(email: "membre@seos.test")
    owner = User.find_by!(email: "association@seos.test")
    admin = User.find_by!(email: "superadmin@seos.test")
    { member => "Camille", owner => "Alex · Entraide solidaire", admin => "Équipe SEOS" }.each do |user, name|
      Profile.find_or_create_by!(user: user) do |profile|
        profile.display_name = name
        profile.public_city = "Lyon"
        profile.bio = "Heureux de partager mes compétences et de rencontrer les personnes du quartier."
        profile.status = "published"
      end
    end
    [
      [ "demo-bricolage", member, categories[0], "Un coup de main pour vos petits travaux", "Je vous aide à monter un meuble ou à poser une étagère. Nous préparons ensemble le matériel nécessaire.", "in_person", "gift" ],
      [ "demo-numerique", owner, categories[2], "Prendre confiance avec son ordinateur", "Un accompagnement patient pour apprendre à utiliser votre ordinateur et les outils du quotidien.", "remote", "gift" ],
      [ "demo-jardin", owner, categories[1], "Jardinage contre un atelier cuisine", "Partageons nos savoir-faire : je vous aide au jardin et vous me faites découvrir votre recette préférée.", "hybrid", "barter" ]
    ].each do |slug, user, category, title, description, location, mode|
      Listing.find_or_create_by!(slug: slug) do |listing|
        listing.assign_attributes(user: user, category: category, title: title, description: description, city: "Lyon", service_location_mode: location,
          exchange_mode: mode, status: "published", published_at: Time.current, wizard_step: 4, availability: "Le samedi, à convenir ensemble")
      end
    end
    {
      "don" => [ "Un coup de main, simplement", "Proposez un service sans contrepartie. Choisissez une annonce, faites connaissance puis convenez des modalités ensemble." ],
      "echange" => [ "Un savoir-faire en rencontre un autre", "Échangez vos compétences. Décrivez ce que chacun propose, puis confirmez ensemble votre accord avant de réaliser le service." ],
      "points" => [ "Les Points Services", "Les PS reconnaissent un service entre membres. Ils ne sont ni achetables, ni vendables, ni convertibles en euros. Les transferts de points ne sont pas encore disponibles." ],
      "fonctionnement" => [ "Comment fonctionne SEOS ?", "Complétez votre profil, publiez une annonce ou répondez à un besoin. Convenez ensemble du service, confirmez sa réalisation puis partagez un avis factuel." ]
    }.each do |slug, (title, body)|
      ContentVersion.find_or_create_by!(kind: "page", slug: slug, version: 1) do |content|
        content.assign_attributes(author: admin, title: title, body: body, published_at: Time.current)
      end
    end
  end
end

load Rails.root.join("db/discovery_demo_photos.rb")
