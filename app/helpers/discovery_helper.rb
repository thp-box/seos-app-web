module DiscoveryHelper
  LABELS = {
    "provisional" => "Provisoire", "confirmed" => "Confirmé", "objected" => "Retiré après objection", "invalidated" => "Invalidé",
    "investigating" => "En cours d’examen", "rejected" => "Maintenu après examen", "simulated" => "Simulé", "approved" => "Approuvé",
    "shadow" => "Calcul en ombre", "active" => "Actif", "retired" => "Retiré", "open" => "Ouvert", "reviewed" => "Examiné", "dismissed" => "Classé sans suite",
    "exchange_burst" => "Échanges rapprochés", "repeated_pair" => "Paire répétée", "referral_burst" => "Parrainages rapprochés", "referral_cycle" => "Cycle de parrainage",
    "created" => "Demande envoyée", "accept" => "Demande acceptée", "decline" => "Demande refusée", "propose" => "Accord proposé", "agree" => "Accord accepté", "confirm" => "Réalisation confirmée", "cancel" => "Annulation", "dispute" => "Ouverture d’un litige", "share" => "Coordonnées partagées", "revoke" => "Partage révoqué",
    "offer" => "Je propose", "request" => "Je cherche", "gift" => "Don", "barter" => "Échange", "points" => "Points Services",
    "in_person" => "Sur place", "remote" => "À distance", "hybrid" => "Sur place ou à distance", "standard" => "Normal", "urgent" => "Urgent",
    "draft" => "Brouillon", "pending_review" => "En revue", "published" => "Publié", "paused" => "En pause", "closed" => "Clôturé", "removed" => "Retiré",
    "pending" => "En attente", "accepted" => "Accepté", "declined" => "Refusé", "scheduled" => "Accord confirmé", "awaiting_confirmation" => "Confirmation attendue",
    "completed" => "Terminé", "cancelled" => "Annulé", "disputed" => "En litige", "expired" => "Expiré"
  }.freeze
  def human_value(value) = LABELS.fetch(value.to_s, value.to_s.humanize)
  def choices_for(values) = values.map { |value| [ human_value(value), value ] }
  def input_field(form, name, label, type: :text_field, **options)
    tag.div(class: "form-field") do
      safe_join([ form.label(name, label), form.public_send(type, name, **options.merge(class: "control")) ])
    end
  end
  def select_field(form, name, label, choices, **options)
    tag.div(class: "form-field") { safe_join([ form.label(name, label), form.select(name, choices, options, class: "control") ]) }
  end
  def plain_paragraphs(text) = simple_format(h(text))
  def public_name(user) = user.profile&.display_name.presence || "Membre SEOS"
  def report_link(record)
    link_to "Signaler", new_account_report_path(target_type: record.class.name, target_id: record.id)
  end
  def profile_schema(profile)
    { "@context" => "https://schema.org", "@type" => "ProfilePage", "@id" => profile_url(profile),
      "mainEntity" => { "@type" => "Person", "@id" => "#{profile_url(profile)}#person", "name" => profile.display_name, "description" => profile.bio } }
  end
  def catalogue_schema(listings)
    { "@context" => "https://schema.org", "@type" => "CollectionPage", "@id" => listings_url,
      "mainEntity" => { "@type" => "ItemList", "itemListElement" => listings.each_with_index.map { |listing, index|
        { "@type" => "ListItem", "position" => index + 1, "url" => listing_url(listing), "name" => listing.title }
      } } }
  end
  def listing_schema(listing)
    service = { "@type" => "Service", "@id" => "#{listing_url(listing)}#service", "name" => listing.title,
      "description" => listing.description, "serviceType" => listing.category.name,
      "areaServed" => listing.location_label, "url" => listing_url(listing),
      "provider" => { "@type" => "Person", "name" => public_name(listing.user), "@id" => "#{profile_url(listing.user.profile)}#person" } }
    payload = listing.intent_offer? ? service : { "@type" => "Demand", "@id" => "#{listing_url(listing)}#demand", "name" => listing.title, "itemOffered" => service }
    payload.merge("@context" => "https://schema.org")
  end
end
