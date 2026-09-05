class ListingsController < ApplicationController
  content_security_policy do |policy|
    template = FeatureFlag.tile_url
    if FeatureFlag.map_enabled? && template.start_with?("https://")
      origin = URI.parse(template.gsub(/\{[^}]+\}/, "a"))
      policy.img_src :self, :data, "https://#{origin.host}"
    end
  end
  def index
    filters = params.permit(:q, :city, :category_id, :intent, :exchange_mode, :service_location_mode, :priority, :sort, :radius).to_h
    @search_coordinates = PublicGeocoding.coordinates(params[:city].to_s.first(100)) if params[:city].present? && params[:radius].present?
    filters.merge!(latitude: @search_coordinates[0], longitude: @search_coordinates[1]) if @search_coordinates
    @results = Catalogue.call(filters)
    @page = [ params[:page].to_i, 1 ].max
    @listings = @results.slice((@page - 1) * 12, 12) || []
    @categories = Category.available
    @map = FeatureFlag.map_enabled? && params[:view] == "map"
    @indexable = params.except(:controller, :action).empty?
    @canonical = listings_url
  end
  def show
    @listing = Listing.find_by!(slug: params[:slug])
    if @listing.removed?
      return render "errors/gone", status: :gone
    end
    raise ActiveRecord::RecordNotFound unless @listing.publicly_visible?
    @indexable = true
    @canonical = listing_url(@listing)
    @description = @listing.description.truncate(160)
    @comments = @listing.comments.visible.includes(user: :profile).order(:created_at).limit(100)
  end
end
