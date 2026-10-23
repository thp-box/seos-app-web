class PartnershipsController < ApplicationController
  before_action do
    @indexable = CrawlerPolicy.current&.search_enabled != false
    @canonical = request.base_url + request.path
  end
  def show
    @partnership_page = PartnershipPage.includes(partner_entries: { logo_attachment: :blob }).current
    @canonical = partnership_page_url
  end
end
