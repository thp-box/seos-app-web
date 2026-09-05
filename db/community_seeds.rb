FeatureFlag.find_or_create_by!(key: "financial_support_enabled") { |flag| flag.enabled = false }
unless ChainRuleVersion.exists?(status: "published")
  version = ChainRuleVersion.new(name: "Chaînes V1 — prestataire, longueur illimitée", status: "published", effective_at: Time.utc(2026, 9, 5), published_at: Time.current)
  version.simulation = { "fingerprint" => version.fingerprint, "maximum_per_validation" => 10, "hundred_validations" => 1000, "length" => "unlimited" }
  version.save!
end
{
  welcome: [ "Bienvenue", "Confirmer votre e-mail, publier votre profil et valider l’accueil dans votre portefeuille.", 1, "once" ],
  listing: [ "Ma première annonce", "Publier une annonce conforme. Chaque annonce éligible est récompensée par le moteur de points.", 1, "once" ],
  responses: [ "Faire trois rencontres", "Obtenir trois demandes acceptées par des membres distincts.", 3, "once" ],
  referral: [ "Parrain principal", "Accompagner un membre actif pendant 30 jours avec deux partenaires distincts hors parrains.", 1, "once" ],
  cycle: [ "L’entraide continue", "Terminer une série de cinq échanges en Points Services.", 5, "cycle" ],
  written: [ "Raconter mon expérience", "Proposer un témoignage écrit consenti et obtenir la validation de sa récompense.", 1, "once" ],
  video: [ "L’entraide en vidéo", "Proposer une vidéo consentie avec transcription puis faire valider sa récompense.", 1, "once" ],
  share: [ "Faire connaître SEOS", "Partager librement SEOS et soumettre une preuve dans le portefeuille, sans traceur imposé.", 1, "monthly" ],
  chain: [ "Passer le relais", "Confirmer un service reçu et aider la personne suivante.", 1, "cycle" ]
}.each_with_index do |(key, (name, description, target, recurrence)), index|
  Achievement.find_or_create_by!(slug: key.to_s) do |quest|
    quest.assign_attributes(name: name, description: description, event_name: key.to_s, reward_key: key.to_s, target_count: target, recurrence: recurrence, builtin: true, position: index)
  end
end
