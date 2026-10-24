class SiteCanvasDocument
  MAX_HTML_SIZE = 750.kilobytes
  MAX_CSS_SIZE = 250.kilobytes
  ALLOWED_TAGS = %w[
    a abbr address article aside b blockquote br button caption cite code col colgroup
    dd details div dl dt em fieldset figcaption figure footer form h1 h2 h3 h4 h5 h6
    header hr i img input label legend li main nav ol option p picture section select
    small source span strong summary svg table tbody td textarea tfoot th thead tr u ul path
  ].freeze
  ALLOWED_ATTRIBUTES = %w[
    abbr accept action alt autocomplete checked class colspan controls decoding disabled
    for height href id loading max maxlength method min minlength multiple name open
    pattern placeholder poster preserveaspectratio rel required role rows rowspan selected src step style target
    title type value viewbox width d fill stroke stroke-width
  ].freeze
  URL_ATTRIBUTES = %w[action href poster src].freeze
  SAFE_URL = %r{\A(?:/|#|https://|mailto:|tel:|data:image/(?:png|jpeg|gif|webp);base64,)}i

  class << self
    def sanitize_html(value)
      return "" unless value.is_a?(String)

      fragment = Nokogiri::HTML5.fragment(value.byteslice(0, MAX_HTML_SIZE))
      fragment.css("script,iframe,object,embed,meta,link,base,template").remove
      fragment.traverse do |node|
        next unless node.element?
        unless ALLOWED_TAGS.include?(node.name)
          node.replace(node.children)
          next
        end
        node.attribute_nodes.each do |attribute|
          name = attribute.name.downcase
          allowed = ALLOWED_ATTRIBUTES.include?(name) || name.start_with?("aria-") || name.start_with?("data-")
          unsafe_url = URL_ATTRIBUTES.include?(name) && !attribute.value.match?(SAFE_URL)
          if name == "style"
            attribute.value = sanitize_css(attribute.value)
          end
          node.remove_attribute(attribute.name) unless allowed && !name.start_with?("on") && !unsafe_url
        end
        if node.name == "a" && node["target"] == "_blank"
          node["rel"] = "noopener noreferrer"
        end
      end
      fragment.to_html
    end

    def sanitize_css(value)
      return "" unless value.is_a?(String)
      css = value.byteslice(0, MAX_CSS_SIZE)
      return "" if css.match?(/@import|expression\s*\(|javascript\s*:|behavior\s*:|-moz-binding|<\/?style|url\s*\(/i)
      css
    end

    def valid?(value)
      value.is_a?(Hash) &&
        (value.keys - %w[html css version]).empty? &&
        value["version"] == 1 &&
        value["html"].is_a?(String) && value["html"].bytesize <= MAX_HTML_SIZE &&
        value["css"].is_a?(String) && value["css"].bytesize <= MAX_CSS_SIZE
    end
  end
end
