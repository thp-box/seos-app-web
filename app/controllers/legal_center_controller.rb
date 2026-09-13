class LegalCenterController < ApplicationController
  before_action :private_response
  def show
    @slug = "legal"
    @page = StudioVersion.current&.site&.dig("pages", "legal") || SiteDesign.default_page("legal")
    @consent = CookieConsent.where(visitor_digest: Digest::SHA256.hexdigest(cookies.signed[:privacy_visitor].to_s), version: CookieConsent::VERSION).where("expires_at > ?", Time.current).order(id: :desc).first
    render "site/show"
  end
end
