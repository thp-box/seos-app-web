xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
  xml.url { xml.loc root_url }
  xml.url { xml.loc listings_url }
  StudioVersion.current&.site&.fetch("pages", {})&.each_key do |slug|
    next if slug == "home"
    xml.url { xml.loc(StudioVersion::PAGES.include?(slug) ? explanation_url(slug) : site_page_url(slug)) }
  end
  xml.url { xml.loc associations_url }
  xml.url { xml.loc volunteer_missions_url } if FeatureFlag.voyage_enabled?
  xml.url { xml.loc partnerships_url } if FeatureFlag.partnerships_enabled?
  Organization.where(status: "verified", kind: "association").where.not(published_at: nil).find_each { |record| xml.url { xml.loc association_url(record) } }
  if FeatureFlag.voyage_enabled?
    VolunteerMission.includes(:organization).where(status: "published").find_each { |record| xml.url { xml.loc volunteer_mission_url(record) } if record.publicly_visible? }
  end
  if FeatureFlag.partnerships_enabled?
    Partnership.includes(:organization).where(status: "published").find_each { |record| xml.url { xml.loc partnership_url(record) } if record.publicly_visible? }
  end
  @listings.each do |listing|
    xml.url do
      xml.loc listing_url(listing)
      xml.lastmod listing.updated_at.iso8601
    end
  end
end
