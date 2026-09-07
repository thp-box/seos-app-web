require 'nokogiri'
require 'json'
require 'digest'
require 'open-uri'
source = File.read('docs/maquette.html')
doc = Nokogiri::HTML(File.read('config/studio/rendered-maquette.html'))
abort 'La maquette a changé : exécutez scripts/render-maquette.rb avant cette extraction.' unless doc.at_css('html')['data-source-sha256'] == Digest::SHA256.hexdigest(source)
css = doc.css('style').map(&:text).join("\n")
images = {}
doc.css('img[src]').each do |img|
  url = img['src']
  next unless url.start_with?('https://images.unsplash.com/')
  name = "maquette/#{URI(url).path.delete_prefix('/')}#{Digest::SHA256.hexdigest(url)[0, 8]}.jpg"
  images[url] = name
end
images.each do |url, name|
  path = "app/assets/images/#{name}"
  next if File.exist?(path)
  begin
    URI.open(url, read_timeout: 20) { |io| File.binwrite(path, io.read) }
  rescue => e
    abort "Image #{url}: #{e.message}"
  end
end
palette = { "004961" => "deep", "0092c5" => "seos", "21a2af" => "turq", "cdae4f" => "gold", "fbfaf4" => "cream", "eef7f9" => "mist", "173947" => "ink", "64767d" => "muted", "d9e4e6" => "line", "ffffff" => "white", "fff" => "white", "dc674f" => "danger", "2e956d" => "ok", "002f40" => "footer" }
rgb_palette = palette.select { |hex, _| hex.size == 6 }.to_h { |hex, token| [ hex.scan(/../).map { |c| c.to_i(16) }, token ] }
theme_colors = lambda do |text|
  text.gsub(/#([0-9a-f]{6}|[0-9a-f]{3})\b/i) { |color| palette.key?(Regexp.last_match(1).downcase) ? "var(--#{palette.fetch(Regexp.last_match(1).downcase)})" : color }.gsub(/rgba?\((\d+),\s*(\d+),\s*(\d+)(?:,\s*([\d.]+))?\)/) do |color|
    token = rgb_palette[[ Regexp.last_match(1).to_i, Regexp.last_match(2).to_i, Regexp.last_match(3).to_i ]]
    alpha = Regexp.last_match(4)
    token ? (alpha ? "color-mix(in srgb,var(--#{token}) #{alpha.to_f * 100}%,transparent)" : "var(--#{token})") : color
  end
end
inline = []
links = { 'home'=>'/', 'don'=>'/decouvrir/don', 'exchange'=>'/decouvrir/echange', 'points'=>'/decouvrir/points', 'listings'=>'/annonces', 'publish'=>'/compte/annonces/new', 'auth'=>'/auth/inscription', 'chain'=>'/decouvrir/fonctionnement' }
clean = lambda do |original|
  node = original.dup
  node.css('script,style,iframe,object,embed').remove
  ([ node ] + node.css('*').to_a).each do |el|
    if el['style']
      name = "source-inline-#{inline.size}"
      inline << ".#{name}{#{el['style']}}"
      el['class'] = [ el['class'], name ].compact.join(' ')
    end
    %w[fill stroke].each { |attribute| el[attribute] = theme_colors.call(el[attribute]) if el[attribute] }
    destination = links[el['data-go']] || (el['data-scroll'] ? '/decouvrir/fonctionnement' : nil)
    el.attribute_nodes.each { |a| el.remove_attribute(a.name) if a.name.start_with?('on', 'data-') || %w[style srcset].include?(a.name) }
    if el.name == 'button'
      el.name = 'a'
      el['href'] = destination || '/contact'
      el.remove_attribute('type')
    end
    el['src'] = images.fetch(el['src'], 'seos-logo.png') if el.name == 'img'
    el['href'] = '/' if el.name == 'a' && !el['href'].to_s.start_with?('/', '#')
    el['disabled'] = 'disabled' if %w[input select textarea].include?(el.name)
    el.remove_attribute('action') if el.name == 'form'
  end
  node
end
library = {}
allowed = { 'home'=>(0..10).to_a, 'don'=>[ 0, 1 ], 'exchange'=>[ 0, 1 ], 'points'=>[ 0, 1 ] }
allowed.each do |page, indexes|
  doc.at_css("main[data-page='#{page}']").element_children.select { |child| child.name == 'section' }.each_with_index do |section, index|
    next unless indexes.include?(index)
    node = clean.call(section)
    # The source search becomes a real GET form without the mock's JavaScript.
    if (search = node.at_css('.search-bar'))
      search.name = 'form'
      search['action'] = '/annonces'
      search['method'] = 'get'
      search.css('input').each_with_index do |input, i|
        input.remove_attribute('disabled')
        input['name'] = i.zero? ? 'q' : 'city'
        input['aria-label'] = i.zero? ? 'Rechercher un service' : 'Ville ou code postal'
      end
      button = search.at_css('a')
      button.name = 'button'
      button.remove_attribute('href')
      button['type'] = 'submit'
    end
    node.css('.testimonial-grid').each { |grid| grid.children.remove } if page == 'home' && index == 6
    node.css('.chain-flow,.chain-home .notice').remove if page == 'home' && index == 4
    node.css('.category-grid,.ad-grid').each { |grid| grid.children.remove } if page == 'home' && [ 2, 3 ].include?(index)
    fields = {}
    node.xpath('.//text()[normalize-space()]').each_with_index do |text, i|
      key = "text-#{i}"
      fields[key] = { 'type'=>'text', 'label'=>text.text.strip[0, 65], 'default'=>text.text.strip }
      if text.parent.name == 'text' && text.ancestors.any? { |ancestor| ancestor.name == 'svg' }
        text.parent['data-field'] = key
        next
      end
      span = Nokogiri::XML::Node.new('span', node.document)
      span['data-field'] = key
      span.content = text.text
      text.replace(span)
    end
    node.css('img').each_with_index do |img, i|
      key = "image-#{i}"
      img['data-image'] = key
      fields[key] = { 'type'=>'image', 'label'=>img['alt'], 'default'=>img['src'] }
      fields["alt-#{i}"] = { 'type'=>'text', 'label'=>"Description image #{i+1}", 'default'=>img['alt'].to_s }
      img['data-alt'] = "alt-#{i}"
    end
    node.css('a').each_with_index do |a, i|
      key = "link-#{i}"
      a['data-link'] = key
      fields[key] = { 'type'=>'url', 'label'=>"Destination : #{a.text.strip[0, 60]}", 'default'=>a['href'] }
    end
    separator = section.next_element
    trailing = separator && separator['class'].to_s.include?('yoga-separator') ? clean.call(separator).to_html : ''
    library["#{page}-#{index}"] = { 'name'=>section.at_css('h1,h2')&.text || page, 'html'=>node.to_html + trailing, 'fields'=>fields }
  end
end
kit = doc.css('main[data-page]').to_h do |page|
  node = clean.call(page)
  node['class'] = 'page active'
  [ page['data-page'], node.to_html ]
end
css += "\n" + inline.join("\n")
# Preserve the original selectors inside a scoped surface; never affect admin/account forms.
css = css.gsub(/:root\s*\{[^}]*\}/m, '').gsub(/(?<![.\w-])body\b/, ':scope').gsub(/(?<![.\w-])html\b/, ':scope')
doc.css('main[data-page]').each do |page|
  css = css.gsub("##{page['id']}", ":is(##{page['id']},[data-maquette-page=\"#{page['data-page']}\"])")
end
css = theme_colors.call(css)
File.write('app/javascript/stylesheets/components/maquette.css', "/* Generated from docs/maquette.html; see config/studio/maquette.json. */\n@scope (.maquette-surface) {\n#{css}\n}\n")
File.write('config/studio/maquette.json', JSON.pretty_generate({ 'sha256'=>Digest::SHA256.hexdigest(source), 'images'=>images, 'sections'=>library, 'kit'=>kit }))
