class PagesController < ApplicationController
  before_action do
    @indexable = CrawlerPolicy.current&.search_enabled != false
    @canonical = request.base_url + request.path
  end
  def home
    @featured_chains = HelpChain.where(featured_on_home: true, status: "active").includes(chain_services: [ :chain_rewards, { provider: :profile, beneficiary: :profile } ]).order(updated_at: :desc).limit(3)
  end
end
