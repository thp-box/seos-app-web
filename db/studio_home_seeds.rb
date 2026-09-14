if Rails.env.development?
  admin = User.find_by!(email: "superadmin@seos.test")
  source = StudioVersion.current
  unless source&.site&.dig("pages", "home")
    site = source&.site&.deep_dup || {}
    site["pages"] ||= {}
    site["pages"]["home"] = SiteDesign.home_page
    version = Studio.change!(actor: admin, source: source, settings: { "site" => site }, name: "Accueil — maquette de démonstration")
    %w[validate publish].each { |action| Studio.transition!(version: version, actor: admin, action: action, reason: "Agencement initial de démonstration") }
  end
  reference = Nokogiri::HTML.fragment(SiteDesign.reference.fetch("kit").fetch("legal"))
  { "cgu" => "cgu", "confidentialite" => "privacy", "cookies" => "cookies", "mentions-legales" => "mentions" }.each do |slug, target|
    next if ContentVersion.current("legal", slug)
    article = reference.at_css("#legal-#{target}")
    next unless article
    body = article.css("h3,p,li").map { |node| node.name == "h3" ? "## #{node.text.strip}" : node.text.strip }.join("\n\n")
    ContentVersion.create!(author: admin, kind: "legal", slug: slug, version: (ContentVersion.where(kind: "legal", slug: slug).maximum(:version) || 0) + 1, title: article.at_css("h2").text, summary: "Démonstration locale issue de la maquette — texte de travail à compléter avant publication réelle.", body: body, published_at: Time.current)
  end
end
