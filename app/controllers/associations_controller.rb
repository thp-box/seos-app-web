class AssociationsController < ApplicationController
  def index
    @organizations = Organization.where(kind: "association", status: "verified").where.not(published_at: nil).order(:name).limit(100)
  end
  def show
    @organization = Organization.find_by!(slug: params[:slug], kind: "association")
    raise ActiveRecord::RecordNotFound unless @organization.publicly_visible?
    @missions = @organization.volunteer_missions.includes(:organization).order(:starts_on).select(&:publicly_visible?)
  end
end
