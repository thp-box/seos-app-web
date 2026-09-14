# Les identifiants de démonstration sont disponibles en développement et en production pour la présentation cliente.
# Les seeds assemblent la home de la maquette sans remplacer une home personnalisée.
if Rails.env.development? || Rails.env.production?
  ApplicationRecord.transaction do
    {
      "membre@seos.test" => :member,
      "superadmin@seos.test" => :super_admin,
      "association@seos.test" => :member,
      "admin@seos.test" => :admin,
      "partenaire@seos.test" => :member
    }.each do |email, role|
      User.find_or_create_by!(email: email) do |user|
        user.role = role
        user.status = :active
        user.password = "SeosDemo2026!"
        user.skip_confirmation!
      end
    end

    association = Organization.find_or_create_by!(slug: "entraide-solidaire-demo") do |organization|
      organization.name = "Entraide solidaire — Démo"
      organization.kind = :association
      organization.status = :verified
    end

    OrganizationMembership.find_or_create_by!(
      organization: association,
      user: User.find_by!(email: "association@seos.test")
    ) do |membership|
      membership.role = :owner
      membership.status = :active
    end
  end

  puts "Jeu de démonstration disponible : 5 comptes et une association (identifiants dans README.md)."
else
  puts "Aucune donnée de démonstration créée dans cet environnement."
end

load Rails.root.join("db/discovery_seeds.rb")
load Rails.root.join("db/trust_seeds.rb")
load Rails.root.join("db/point_seeds.rb")

load Rails.root.join("db/community_seeds.rb")

load Rails.root.join("db/network_seeds.rb")

load Rails.root.join("db/launch_seeds.rb")

load Rails.root.join("db/travel_seeds.rb")

load Rails.root.join("db/studio_home_seeds.rb")
load Rails.root.join("db/home_category_seeds.rb")
