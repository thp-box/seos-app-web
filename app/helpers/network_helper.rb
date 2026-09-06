module NetworkHelper
  def network_label(value)
    { "verified" => "Vérifiée", "pending" => "En attente", "rejected" => "Refusée", "suspended" => "Suspendue", "draft" => "Brouillon", "pending_review" => "En revue", "published" => "Publié", "paused" => "En pause", "archived" => "Archivé", "accepted" => "Acceptée", "withdrawn" => "Retirée", "association" => "Association", "company" => "Entreprise", "institution" => "Institution", "collective" => "Collectif", "institutional" => "Institutionnel", "operational" => "Opérationnel", "technical" => "Technique", "support" => "Soutien" }.fetch(value) { human_value(value) }
  end
  def network_choices(values) = values.map { |value| [ network_label(value), value ] }
end
