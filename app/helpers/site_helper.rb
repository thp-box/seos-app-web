module SiteHelper
  PAGE_NAMES = { "voyage-solidaire" => "Voyage solidaire", "communaute" => "La communauté", "home" => "Accueil", "don" => "Le don", "echange" => "L’échange", "points" => "Les Points Services", "fonctionnement" => "Comment ça marche ?" }.freeze
  SECTION_NAMES = { "travel-hero" => "Voyage solidaire : présentation", "travel-missions" => "Voyage solidaire : missions et filtre", "spacer" => "Section vide", "community-app" => "La communauté : l’application", "community-associations" => "La communauté : les associations", "community-support" => "La communauté : participer", "home-0" => "Grande présentation avec photo", "home-1" => "Les trois façons de s’entraider", "home-2" => "Catégories d’annonces", "home-3" => "Annonces récentes", "home-4" => "La chaîne d’entraide", "home-5" => "Présentation de SEOS", "home-6" => "Témoignages de membres", "home-7" => "Confiance et sécurité", "home-8" => "La communauté francophone", "home-9" => "Invitation à nous rejoindre", "home-10" => "Soutenir SEOS", "don-0" => "Présentation du don", "don-1" => "Le don en trois étapes", "exchange-0" => "Présentation de l’échange", "exchange-1" => "L’échange en trois étapes", "points-0" => "Présentation des Points Services", "points-1" => "Les Points Services en trois étapes", "text" => "Texte libre" }.freeze
  COLOR_NAMES = { "deep" => "Bleu principal", "seos" => "Bleu des liens et accents", "turq" => "Turquoise", "gold" => "Doré des boutons", "cream" => "Fond des pages", "mist" => "Fond des encadrés", "ink" => "Textes principaux", "muted" => "Textes secondaires", "line" => "Bordures", "white" => "Surfaces claires", "danger" => "Alertes", "ok" => "Confirmations", "footer" => "Fond du bas de page" }.freeze
  def site_kit_screen_name(key)
    { "home" => "Accueil", "don" => "Don", "exchange" => "Échange", "points" => "Points Services", "listings" => "Liste des annonces", "detail" => "Détail d’une annonce", "publish" => "Création d’une annonce", "auth" => "Connexion et inscription", "dashboard" => "Espace membre", "chain" => "Chaîne d’entraide", "travel" => "Voyage solidaire", "admin" => "Gestion du site", "chain-validation" => "Confirmation d’un service", "legal" => "Informations légales" }.fetch(key)
  end
  def site_page_name(slug, version = nil) = version&.site&.dig("pages", slug, "title") || PAGE_NAMES.fetch(slug, slug.humanize)
  def site_page_description(slug)
    { "home" => "La première page que découvrent vos visiteurs.", "don" => "Expliquez comment donner un coup de main.", "echange" => "Présentez les échanges entre membres.", "points" => "Expliquez le fonctionnement des Points Services.", "fonctionnement" => "Accompagnez les nouveaux visiteurs." }.fetch(slug, "Une page de présentation de votre site.")
  end
  def site_section_name(key) = SECTION_NAMES.fetch(key)
  def site_section_description(key)
    return "Un espace vide avec une hauteur réglable, sur ordinateur et téléphone." if key == "spacer"
    return "Les annonces visibles du site s’affichent ici automatiquement." if key == "home-3"
    return "Les témoignages acceptés et publiés s’affichent ici automatiquement." if key == "home-6"
    return "Les catégories disponibles s’affichent ici automatiquement." if key == "home-2"
    return "Un titre et un texte à écrire librement. Vous pouvez ajouter un bouton si besoin." if key == "text"
    return "Une grande introduction avec un titre, une photo et un bouton pour orienter les visiteurs." if key.end_with?("-0")
    "Une présentation prête à adapter : personnalisez ses textes, ses images et ses liens."
  end
  def site_workspace_action(label, version, **options)
    if version
      link_to label, edit_admin_site_path(version, **options), class: "btn btn-deep"
    else
      button_to label, admin_site_index_path, params: options, class: "btn btn-deep"
    end
  end
  def site_token_choices(key, values)
    values.map do |value|
      label = case key
      when "motion" then { "none" => "Aucune animation", "subtle" => "Mouvements doux", "standard" => "Mouvements normaux" }.fetch(value)
      when "wave-shape" then { "wave" => "Vague", "curve" => "Courbe", "diagonal" => "Diagonale", "flat" => "Ligne droite" }.fetch(value)
      when "shadow" then value == "none" ? "Sans ombre" : "Ombre douce"
      when "font-body", "font-heading" then value.split(",").first == "system-ui" ? "Police de l’appareil" : value.split(",").first
      when "wave-speed" then "Un mouvement toutes les #{value.delete_suffix('s')} secondes"
      else [ "Très léger", "Léger", "Prononcé", "Très prononcé" ][values.index(value)]
      end
      [ label, value ]
    end
  end
  def site_review_changes(version, live)
    before = live&.settings || {}
    changes = []
    old_pages = before.dig("site", "pages") || {}
    new_pages = version.site.fetch("pages", {})
    (old_pages.keys | new_pages.keys).each do |slug|
      changes << "Page : #{site_page_name(slug, version)}" if old_pages[slug] != new_pages[slug]
    end
    %w[header footer].each do |area|
      changes << (area == "header" ? "Haut du site : logo et menu" : "Bas du site : informations et liens") if before.dig("site", area) != version.site[area]
    end
    changes << "Couleurs et apparence de l’ensemble du site" if before.fetch("tokens", {}) != version.tokens
    changes << "Autres textes et présentations enregistrés" if before.fetch("pages", {}) != version.settings.fetch("pages", {}) || version.settings["editorial_resets"].present?
    changes
  end
  def site_image_options(assets)
    [ [ "Logo SEOS", "seos-logo.png" ] ] + assets.map { |asset| [ "Image importée ##{asset.id}", "asset:#{asset.id}" ] } + SiteDesign.reference["images"].values.uniq.each_with_index.map { |path, i| [ "Maquette — photo #{i + 1}", path ] }
  end
  def site_token_label(key)
    { "radius" => "Arrondi général", "font-body" => "Police des textes", "font-heading" => "Police des titres", "motion" => "Animations du site", "button-radius" => "Arrondi des boutons", "card-radius" => "Arrondi des cartes", "section-space" => "Espacement des sections", "wave-height" => "Hauteur des vagues", "wave-speed" => "Durée d’un cycle de vague", "wave-amplitude" => "Amplitude des vagues", "wave-shape" => "Forme des vagues", "shadow" => "Ombre des cartes" }.fetch(key)
  end
  def site_version = @studio_version || (@published_site_version ||= StudioVersion.current)
  def site_chrome(area) = site_version&.chrome(area) || SiteDesign::CHROME.fetch(area)
  def site_image_path(value)
    value.start_with?("asset:") ? media_path(StudioAsset.find(value.delete_prefix("asset:")).image.attachment) : image_path(value)
  end
  def site_public_path(slug)
    return volunteer_missions_path if slug == "voyage-solidaire"
    return community_path if slug == "communaute"
    return root_path if slug == "home"
    StudioVersion::PAGES.include?(slug) ? explanation_path(slug) : site_page_path(slug)
  end
  def maquette_html(html, block: nil, secondary_heading: false)
    doc = Nokogiri::HTML.fragment(html)
    doc.css("h1").each { |node| node.name = "h2" } if secondary_heading
    if block
      fields = SiteDesign.templates.fetch(block["template"]).fetch("fields")
      values = fields.transform_values { |field| field["default"] }.merge(block["values"])
      doc.css("[data-field]").each do |node|
        value = values.fetch(node["data-field"])
        # Keep the source spacing between adjacent parts of a title after editing.
        leading = value.match?(/\A\s/) ? "" : node.text[/\A\s*/]
        trailing = value.match?(/\s\z/) ? "" : node.text[/\s*\z/]
        node.content = "#{leading}#{value}#{trailing}"
      end
      doc.css("[data-link]").each { |node| node["href"] = values.fetch(node["data-link"]) }
      doc.css("[data-image]").each { |node| node["src"] = values.fetch(node["data-image"]); node["alt"] = values.fetch(node["data-alt"]) }
      identifiers = doc.css("[id]").to_h { |node| [ node["id"], "#{block['id']}-#{node['id']}" ] }
      doc.css("*").each do |node|
        node.attribute_nodes.each do |attribute|
          attribute.value = attribute.value.gsub(/url\(#([^)]+)\)/) { "url(##{identifiers.fetch(Regexp.last_match(1), Regexp.last_match(1))})" }
        end
        node["id"] = identifiers.fetch(node["id"]) if node["id"]
      end
    end
    doc.css("img").each { |node| node["src"] = site_image_path(node["src"]); node["loading"] = "lazy" }
    slots = { "home-2" => [ ".category-grid", "categories" ], "home-3" => [ ".ad-grid", "listings" ], "home-6" => [ ".testimonial-grid", "testimonials" ] }
    if block && (slot = slots[block["template"]])
      doc.at_css(slot.first).inner_html = render("site/#{slot.last}")
    end
    if block && block["template"] == "travel-missions"
      doc.at_css(".travel-missions-slot").inner_html = render("volunteer_missions/catalogue", values: values, block_id: block["id"])
    end
    # All markup comes from the checked-in reference. User values enter through text/attribute setters.
    doc.to_html.html_safe
  end
end
