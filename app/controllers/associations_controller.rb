class AssociationsController < ApplicationController
  before_action do
    @indexable = CrawlerPolicy.current&.search_enabled != false
    @canonical = request.base_url + request.path
  end
  def index
    @organizations = Organization.where(kind: "association", status: "verified").where.not(published_at: nil).order(:name).limit(100)
  end
  def show
    @organization = Organization.find_by!(slug: params[:slug], kind: "association")
    raise ActiveRecord::RecordNotFound unless @organization.publicly_visible?
    @missions = @organization.volunteer_missions.includes(:organization).order(:starts_on).select(&:publicly_visible?)
  end
end
