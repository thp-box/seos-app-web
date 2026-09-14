module NetworkHelper
  def organization_project_kind(organization)
    organization.request_kind.presence || (organization.association? ? "community_mission" : "partnership")
  end

  def organization_next_step(organization)
    case organization.status
    when "verified" then "Votre structure est vérifiée. Préparez votre projet, puis soumettez-le à l’équipe SEOS pour publication."
    when "pending" then "Votre demande est en cours d’examen. Vous pouvez compléter votre présentation pendant la vérification."
    when "rejected" then "Votre demande n’a pas été retenue. Complétez votre dossier et demandez une nouvelle revue."
    when "suspended" then "Cet espace est suspendu. Contactez l’équipe SEOS pour faire le point sur votre situation."
    end
  end

  def network_label(value)
    { "verified" => "Vérifiée", "pending" => "En attente", "rejected" => "Refusée", "suspended" => "Suspendue", "draft" => "Brouillon", "pending_review" => "En revue", "published" => "Publié", "paused" => "En pause", "archived" => "Archivé", "accepted" => "Acceptée", "withdrawn" => "Retirée", "association" => "Association", "company" => "Entreprise", "micro_company" => "Micro-entreprise", "partnership" => "Partenariat", "community_mission" => "Mission communautaire", "institution" => "Institution", "collective" => "Collectif", "institutional" => "Institutionnel", "operational" => "Opérationnel", "technical" => "Technique", "support" => "Soutien" }.fetch(value) { human_value(value) }
  end
  def network_choices(values) = values.map { |value| [ network_label(value), value ] }
end
