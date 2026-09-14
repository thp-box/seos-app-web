module AdminSupervisionHelper
  REGISTER_LABELS = {
    "user" => "Membres", "profile" => "Profils publics", "listing" => "Annonces", "report" => "Signalements",
    "review" => "Avis", "review_rating" => "Notes des avis", "review_criterion" => "Critères des avis",
    "organization" => "Organisations", "volunteer_mission" => "Missions communautaires", "partnership" => "Partenariats",
    "audit_log" => "Journal d’audit", "bulk_operation" => "Opérations groupées", "login_session" => "Sessions de connexion",
    "login_block" => "Blocages de connexion", "admin_permission_grant" => "Droits administratifs",
    "trust_score_snapshot" => "Historique des scores de confiance", "trust_profile" => "Scores de confiance publiés",
    "trust_event" => "Événements de confiance", "trust_appeal" => "Recours de confiance",
    "point_entry" => "Écritures de Points Services", "point_operation" => "Opérations de Points Services",
    "point_account" => "Comptes de Points Services", "mail_delivery" => "Envois d’e-mails", "message" => "Références des messages",
    "service_request" => "Échanges", "crawler_policy" => "Consignes aux robots", "feature_flag" => "Activation des fonctionnalités",
    "data_request" => "Demandes de droits", "cookie_consent" => "Choix de cookies", "notification" => "Notifications",
    "financial_contribution" => "Contributions financières", "payment_event" => "Événements de paiement"
  }.freeze
  def supervision_register_label(key, model)
    REGISTER_LABELS.fetch(key) { model.model_name.human } + " · #{key}"
  end
end
