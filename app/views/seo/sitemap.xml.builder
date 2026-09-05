xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do
  xml.url { xml.loc listings_url }
  @listings.each do |listing|
    xml.url do
      xml.loc listing_url(listing)
      xml.lastmod listing.updated_at.iso8601
    end
  end
end
