module CommunityHelper
  def community_status(value)
    { "submitted" => "En revue", "pending" => "En attente", "approved" => "Validé", "rejected" => "Refusé", "published" => "Publié", "removed" => "Retiré", "withdrawn" => "Retiré", "expired" => "Expiré", "active" => "Active", "closed" => "Clôturée", "disputed" => "En médiation", "invited" => "Confirmation attendue", "confirmed" => "Confirmé", "cancelled" => "Annulé", "paid" => "Encaissé", "failed" => "Échec", "refund_pending" => "Remboursement en cours", "partially_refunded" => "Partiellement remboursé", "refunded" => "Remboursé", "draft" => "Brouillon", "simulated" => "Simulé" }.fetch(value, value)
  end
  def community_level(value) = { "bronze" => "Bronze", "silver" => "Argent", "gold" => "Or" }.fetch(value)
end
