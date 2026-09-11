# Presentation metadata only: source field keys and saved values remain unchanged.
class SiteSectionEditor
  attr_reader :groups

  def initialize(template)
    @template = template
    @doc = Nokogiri::HTML.fragment(template.fetch("html"))
    @groups = { "Titre de cette partie" => [] }
    template.fetch("fields").each do |key, field|
      node = @doc.at_css("[data-field='#{key}'],[data-image='#{key}'],[data-alt='#{key}'],[data-link='#{key}']")
      next if decorative?(node, field)
      group, label, help = describe(node, key, field)
      (@groups[group] ||= []) << field.merge("key" => key, "label" => label, "help" => help)
    end
    @groups.reject! { |_name, fields| fields.empty? }
  end

  private

  def within(node, selector)
    ([ node ] + node.ancestors.to_a).find { |element| element.element? && element.matches?(selector) }
  end

  def decorative?(node, field)
    field["type"] == "text" && (within(node, ".search-field,.exchange-num,.icon-btn,svg") || (within(node, ".info-step") && within(node, "b")) || !field["default"].match?(/[[:alnum:]]/))
  end

  def describe(node, key, field)
    if %w[image alt].any? { |prefix| key.start_with?("#{prefix}-") }
      number = key.split("-").last.to_i + 1
      return [ "Photos", "Photo #{number} — #{field['type'] == 'image' ? 'Image à afficher' : 'Description pour l’accessibilité'}", field["type"] == "image" ? "Choisissez la photo qui apparaîtra dans cette partie de la page." : "Décrivez brièvement ce que montre cette photo, pour les personnes qui ne peuvent pas la voir." ]
    end
    if (button = within(node, "a,button"))
      buttons = @doc.css("a,button")
      number = buttons.index(button) + 1
      group = button.matches?(".icon-btn") ? "Liens de partage" : "Bouton #{number} — #{button.text.strip}"
      label = field["type"] == "url" ? "Page à ouvrir au clic" : "Texte du bouton"
      label = "Adresse de partage #{number}" if button.matches?(".icon-btn")
      return [ group, label, field["type"] == "url" ? "Exemple : /contact pour une page du site, ou une adresse complète commençant par https://." : "Ce texte indique aux visiteurs ce qui se passe lorsqu’ils cliquent." ]
    end
    if within(node, ".hero-label")
      number = @doc.css(".hero-label [data-field]").index(node) + 1
      return [ "Petit bandeau au-dessus du titre", "Bandeau — partie #{number}", "Les deux parties apparaissent côte à côte dans le petit bandeau en haut de la présentation." ]
    end
    if within(node, ".security-orb")
      return [ "Texte dans la forme décorative", "Ligne #{@doc.css('.security-orb [data-field]').reject { |item| !item.text.match?(/[[:alnum:]]/) }.index(node) + 1}", "Ce texte est placé dans la forme qui bouge doucement lorsque les animations sont activées." ]
    end
    if within(node, ".francophone-flag-photo")
      return [ "Légendes des pays", "Nom sous la photo #{@doc.css('.francophone-flag-photo [data-field]').index(node) + 1}", "Le nom affiché sur la photo du pays." ]
    end
    article = within(node, "article")
    group = article ? "Encadré #{@doc.css('article').index(article) + 1} — #{article.at_css('h3')&.text&.strip}" : "Titre de cette partie"
    if within(node, ".eyebrow")
      return [ group, "Petit texte au-dessus du titre", "Une courte indication qui présente le sujet de cette partie." ]
    end
    if (heading = within(node, "h1,h2,h3"))
      parts = heading.css("[data-field]")
      if within(node, ".accent")
        return [ group, "Mots du titre en couleur", "La suite du titre, affichée en couleur et en italique. Ces mots ne sont pas animés." ]
      end
      label = parts.size == 1 ? "Titre" : (parts.index(node).zero? ? "Début du titre" : "Suite du titre")
      return [ group, label, parts.size == 1 ? "Le titre visible de cette partie." : "Les champs du titre sont réunis dans leur ordre d’affichage pour former une seule phrase." ]
    end
    if within(node, ".caption")
      return [ "Légende du visuel", "Texte sur le visuel", "La légende affichée sur l’emplacement de présentation vidéo." ]
    end
    peers = (article || @doc).css("p [data-field],.notice [data-field]")
    number = peers.index(node)
    label = peers.size > 1 && number ? "Texte de présentation — partie #{number + 1}" : "Texte de présentation"
    [ article ? group : "Texte de présentation", label, within(node, "strong") ? "Ce passage apparaît en gras dans le texte de présentation." : "Le texte explicatif à lire dans cette partie, dans l’ordre affiché ici." ]
  end
end
