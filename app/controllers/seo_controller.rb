class SeoController < ApplicationController
  def sitemap
    @listings = Catalogue.call({})
    render formats: :xml
  end
  def robots
    render plain: "User-agent: *\nDisallow: /compte\nDisallow: /auth\nDisallow: /admin\nDisallow: /super_admin\nDisallow: /membres\nDisallow: /organisations\nUser-agent: GPTBot\nDisallow: /\nUser-agent: OAI-SearchBot\nAllow: /annonces\nDisallow: /compte\nDisallow: /auth\nDisallow: /admin\nDisallow: /super_admin\nDisallow: /membres\nDisallow: /organisations\nSitemap: #{sitemap_url}\n"
  end
end
