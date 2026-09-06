class VolunteerMissionsController < ApplicationController
  before_action do
    @indexable = CrawlerPolicy.current&.search_enabled != false
    @canonical = request.base_url + request.path
  end
  before_action { raise ActiveRecord::RecordNotFound unless FeatureFlag.voyage_enabled? }
  def index
    scope = VolunteerMission.where(status: "published").where("ends_on >= ?", Date.current).joins(:organization).where(organizations: { status: "verified", kind: "association" }).includes(:organization).order(:starts_on)
    scope = scope.where(country_code: params[:country].to_s.upcase) if params[:country].present?
    @missions = scope.limit(100).select(&:publicly_visible?)
  end
  def show
    @mission = VolunteerMission.find_by!(slug: params[:slug])
    raise ActiveRecord::RecordNotFound unless @mission.publicly_visible?
  end
end
