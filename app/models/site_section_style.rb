# Only application-owned CSS can be selected in the visual editor.
class SiteSectionStyle
  OPTIONS = {
    "size" => { "normal" => "Taille d’origine", "small" => "Plus petit", "large" => "Plus grand" },
    "space" => { "normal" => "Espacement d’origine", "compact" => "Rapproché", "airy" => "Aéré" },
    "shape" => { "normal" => "Forme d’origine", "rounded" => "Arrondie", "organic" => "Organique" },
    "animation" => { "none" => "Sans animation", "appear" => "Apparition douce", "float" => "Flottement doux", "breathe" => "Respiration" }
  }.freeze
  def self.valid?(style)
    style.is_a?(Hash) && style.all? { |key, value| OPTIONS.fetch(key, {}).key?(value) }
  end
  def self.css(block)
    selector = "#site-section-#{block.fetch('id')}"
    if block["template"] == "spacer"
      fields = SiteDesign.templates.fetch("spacer").fetch("fields")
      heights = fields.to_h { |key, field| [ key, block.fetch("values", {}).fetch(key, field["default"]).to_i.clamp(8, 1200) ] }
      return "#{selector} .site-spacer{height:#{heights['height']}px}@media(max-width:760px){#{selector} .site-spacer{height:#{heights['mobile_height']}px}}"
    end
    css = rules(selector, block.fetch("style", {}), section: true)
    block.fetch("elements", {}).each do |field, style|
      # Field identifiers come from the reference schema, never from arbitrary selectors.
      css += rules("#{selector} [data-field=#{field}],#{selector} [data-image=#{field}]", style, section: false)
    end
    css
  end
  def self.rules(selector, style, section:)
    rules = []
    target = section ? "#{selector} :is(h1,h2,h3)" : ":is(#{selector})"
    rules << "#{target}{font-size:#{style['size'] == 'small' ? '0.85em' : '1.2em'}}" if !section && %w[small large].include?(style["size"])
    rules << "#{target}{font-size:#{style['size'] == 'small' ? 'clamp(1.5rem,3vw,2.8rem)' : 'clamp(2.5rem,6vw,5rem)'}}" if section && %w[small large].include?(style["size"])
    rules << "#{selector} .section,#{selector} > section{padding-block:#{style['space'] == 'compact' ? '32px' : '112px'}}" if section && %w[compact airy].include?(style["space"])
    rules << ":is(#{selector})[data-image]{width:#{style['size'] == 'small' ? '70%' : '100%'};max-width:100%}" if !section && %w[small large].include?(style["size"])
    rules << "#{target}:is(h1,h2,h3){font-size:#{style['size'] == 'small' ? 'clamp(1.5rem,3vw,2.8rem)' : 'clamp(2.5rem,6vw,5rem)'}}" if !section && %w[small large].include?(style["size"])
    image = section ? "#{selector} img" : ":is(#{selector})"
    rules << "#{image}{border-radius:#{style['shape'] == 'organic' ? '58% 42% 65% 35% / 40% 65% 35% 60%' : '32px'}}" if %w[rounded organic].include?(style["shape"])
    if %w[appear float breathe].include?(style["animation"])
      animation = { "appear" => "site-appear .7s ease-out both", "float" => "site-float 6s ease-in-out infinite alternate", "breathe" => "site-breathe 8s ease-in-out infinite alternate" }.fetch(style["animation"])
      rules << ":is(#{selector}){animation:#{animation};#{'display:inline-block' unless section}}"
    end
    rules.join
  end
end
