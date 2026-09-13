module FooterHelper
  LEGAL_LABELS = { "cgu" => "Règles et CGU", "confidentialite" => "Confidentialité & RGPD", "cookies" => "Cookies", "mentions-legales" => "Mentions légales" }.freeze
  def unified_legal_url(url)
    return legal_center_path(anchor: "legal-securite") if url == trust_explanation_path
    return legal_center_path(anchor: "legal-introduction") if url == legal_center_path
    return privacy_preferences_path if url == privacy_preferences_path
    slug = url.delete_prefix("/legal/")
    ContentVersion::LEGAL_SLUGS.include?(slug) ? legal_center_path(anchor: "legal-#{slug}") : url
  end
  def footer_groups(chrome)
    groups = {
      "Découvrir" => [ [ "Le concept", "/#presentation" ], [ "Les annonces", "/annonces" ], [ "Chaîne d’entraide", "/#site-section-home-4" ] ],
      "Participer" => [ [ "Publier", new_account_listing_path ], [ "Voyage solidaire", volunteer_missions_path ], [ "Mon espace", account_root_path ] ],
      "Confiance" => [ [ "Sécurité", trust_explanation_path ], [ "Règles et CGU", legal_path("cgu") ], [ "Centre légal", legal_center_path ] ],
      "Informations légales" => [ [ "Mentions légales", legal_path("mentions-legales") ], [ "Confidentialité & RGPD", legal_path("confidentialite") ], [ "Cookies", legal_path("cookies") ], [ "Gérer mes cookies", privacy_preferences_path ] ]
    }
    known = groups.values.flatten(1).map(&:last)
    chrome["links"].each do |link|
      link = link.merge("url" => "/#presentation") if link["url"] == "/decouvrir/fonctionnement"
      existing = groups.values.flatten(1).find { |item| item.last == link["url"] }
      if existing
        existing[0] = link["label"]
      elsif !known.include?(link["url"])
        groups["Découvrir"] << [ link["label"], link["url"] ]
      end
    end
    removed = (site_version&.deleted_pages || []).flat_map { |slug| SiteDesign.page_paths(slug) }
    groups.transform_values { |links| links.map { |label, url| [ label, unified_legal_url(url) ] }.reject { |_label, url| removed.include?(url.split(/[?#]/).first) || (url == volunteer_missions_path && !FeatureFlag.voyage_enabled?) } }
  end
end
