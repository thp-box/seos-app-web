# A declarative document: user content never supplies HTML, CSS or JavaScript.
class SiteDesign
  SOURCE = Rails.root.join("config/studio/maquette.json")
  CHROME = {
    "header" => { "mobile_join_label" => "Créer un compte", "join_label" => "Rejoindre SEOS", "login_label" => "Connexion", "account_label" => "Mon espace", "logo" => "seos-logo.png", "alt" => "SEOS", "links" => [ { "label" => "Les annonces", "url" => "/annonces" }, { "label" => "Le journal", "url" => "/journal" } ] },
    "footer" => { "logo" => "seos-logo.png", "alt" => "SEOS", "title" => "Les petits gestes font les grands liens.", "description" => "L’entraide locale, en France.", "links" => [ { "label" => "Contact", "url" => "/contact" }, { "label" => "Don", "url" => "/decouvrir/don" }, { "label" => "Échange", "url" => "/decouvrir/echange" }, { "label" => "Points Services", "url" => "/decouvrir/points" }, { "label" => "Le journal", "url" => "/journal" } ] }
  }.freeze
  def self.reference = @reference ||= JSON.parse(SOURCE.read)
  def self.templates
    reference.fetch("sections").merge("text" => { "name" => "Texte et bouton", "fields" => {
      "title" => { "type" => "text", "label" => "Titre", "default" => "Votre titre" },
      "body" => { "type" => "text", "label" => "Contenu", "default" => "Votre contenu" },
      "label" => { "type" => "text", "label" => "Bouton", "default" => "En savoir plus" },
      "url" => { "type" => "url", "label" => "Destination", "default" => "/contact" }
    } })
  end
  def self.safe_url?(value)
    return false unless value.is_a?(String) && value.size <= 2000 && !value.match?(/[\s\\\x00-\x1f]/)
    return true if value.match?(/\A\/(?!\/)/) || value.match?(/\A#[a-zA-Z][\w-]*\z/)
    uri = URI.parse(value)
    uri.is_a?(URI::HTTPS) && uri.host.present? && uri.userinfo.nil?
  rescue URI::InvalidURIError
    false
  end
  def self.image?(value)
    value == "seos-logo.png" || reference.fetch("images").value?(value) || (value.is_a?(String) && value.match?(/\Aasset:\d+\z/) && StudioAsset.joins(:image_attachment).exists?(id: value.delete_prefix("asset:")))
  end
  def self.text?(value) = value.is_a?(String) && value.size <= 15_000 && !value.include?("\u0000")
  def self.valid?(data)
    return false unless data.is_a?(Hash) && (data.keys - %w[pages header footer]).empty?
    %w[header footer].each do |area|
      next unless data.key?(area)
      chrome = data[area]
      return false unless chrome.is_a?(Hash) && (chrome.keys - CHROME.fetch(area).keys).empty?
      return false unless chrome.all? { |key, value| case key
                                                     when "logo" then image?(value)
                                                     when "links" then value.is_a?(Array) && value.size <= 12 && value.all? { |link| link.is_a?(Hash) && link.keys.sort == %w[label url] && text?(link["label"]) && link["label"].present? && safe_url?(link["url"]) }
                                                     else text?(value)
                                                     end }
      return false if chrome.any? { |key, value| key.end_with?("_label") && value.blank? }
      return false if chrome["logo"].present? && chrome["alt"].blank?
    end
    pages = data.fetch("pages", {})
    return false unless pages.is_a?(Hash) && pages.size <= 50
    pages.all? do |slug, page|
      slug.match?(/\A[a-z][a-z0-9-]{0,70}\z/) && page.is_a?(Hash) && (page.keys - %w[title blocks]).empty? && text?(page["title"]) && page["title"].present? && page["blocks"].is_a?(Array) && page["blocks"].size <= 40 && page["blocks"].map { |b| b.is_a?(Hash) ? b["id"] : nil }.uniq.size == page["blocks"].size && page["blocks"].all? { |block| valid_block?(block) }
    end
  end
  def self.valid_block?(block)
    return false unless block.is_a?(Hash) && (block.keys - %w[id template values hidden separator placement style elements]).empty? && block["id"].is_a?(String) && block["id"].match?(/\A[a-z0-9-]{1,50}\z/) && [ true, false, nil ].include?(block["hidden"])
    return false unless [ nil, "none", *ContentVersion::PRESETS ].include?(block["separator"]) && [ nil, "top", "bottom" ].include?(block["placement"])
    template = templates[block["template"]]
    return false unless SiteSectionStyle.valid?(block.fetch("style", {}))
    elements = block.fetch("elements", {})
    return false unless elements.is_a?(Hash) && template && elements.all? { |field, style| template["fields"].key?(field) && SiteSectionStyle.valid?(style) }
    values = block["values"]
    return false unless template && values.is_a?(Hash) && (values.keys - template["fields"].keys).empty?
    values.all? do |key, value|
      case template["fields"][key]["type"]
      when "url" then safe_url?(value)
      when "image" then image?(value)
      else text?(value)
      end
    end && template["fields"].keys.grep(/\Aimage-/).all? { |key| values.fetch(key.sub("image-", "alt-"), template["fields"][key.sub("image-", "alt-")]["default"]).present? }
  end
  def self.default_page(slug)
    title = slug == "home" ? "Accueil" : ContentVersion.current("page", slug)&.title || slug.humanize
    content = ContentVersion.current("page", slug)
    blocks = content ? [ { "id" => "initial-#{slug}", "template" => "text", "values" => { "title" => title, "body" => [ content.summary, content.body ].compact.join("\n\n") } } ] : []
    { "title" => title, "blocks" => blocks }
  end
end
