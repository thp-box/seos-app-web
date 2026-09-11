class SeoController < ApplicationController
  PRIVATE_PATHS = %w[/compte /auth /admin /super_admin /membres /organisations /medias /preferences-confidentialite].freeze
  def sitemap
    @listings = Catalogue.call({})
    render formats: :xml
  end
  def robots
    policy = CrawlerPolicy.current
    private_rules = PRIVATE_PATHS.map { |path| "Disallow: #{path}\n" }.join
    rules = "User-agent: *\n#{policy&.search_enabled == false ? "Disallow: /\n" : private_rules}"
    %w[GPTBot Google-Extended ClaudeBot CCBot].each do |bot|
      rules += "User-agent: #{bot}\n#{policy&.training_enabled == true ? private_rules : "Disallow: /\n"}"
    end
    rules += "User-agent: OAI-SearchBot\n#{policy&.search_enabled == false ? "Disallow: /\n" : "Allow: /annonces\n#{private_rules}"}Sitemap: #{sitemap_url}\n"
    render plain: rules
  end
end
