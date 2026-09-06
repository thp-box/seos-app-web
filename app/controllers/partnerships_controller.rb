class PartnershipsController < ApplicationController
  before_action { raise ActiveRecord::RecordNotFound unless FeatureFlag.partnerships_enabled? }
  def index
    @partnerships = Partnership.where(status: "published").where("starts_on <= ? AND ends_on >= ?", Date.current, Date.current).joins(:organization).where(organizations: { status: "verified" }).includes(:organization).order(:position, :id).limit(100).select(&:publicly_visible?)
  end
  def show
    @partnership = Partnership.find_by!(slug: params[:slug])
    raise ActiveRecord::RecordNotFound unless @partnership.publicly_visible?
  end
end
