class PagesController < ApplicationController
  before_action do
    @indexable = CrawlerPolicy.current&.search_enabled != false
    @canonical = request.base_url + request.path
  end
  def home
  end
end
