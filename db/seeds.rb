# Les identifiants de démonstration sont réservés au développement.
# Les références immuables du Studio seront ajoutées avec F-008/F-009.
if Rails.env.development?
  ApplicationRecord.transaction do
    {
      "membre@seos.test" => :member,
      "superadmin@seos.test" => :super_admin,
      "association@seos.test" => :member
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

  puts "Jeu de démonstration disponible : 3 comptes et une association (identifiants dans README.md)."
else
  puts "Aucune donnée de démonstration créée hors développement."
end

load Rails.root.join("db/discovery_seeds.rb")
load Rails.root.join("db/trust_seeds.rb")
