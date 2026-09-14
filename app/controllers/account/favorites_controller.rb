module Account
  class FavoritesController < BaseController
    def index
      @listings = current_user.favorites.includes(listing: [ :category, { user: :profile } ]).map(&:listing).select(&:publicly_visible?)
    end
    def create
      listing = Listing.find_by!(slug: params[:listing_slug])
      raise ActiveRecord::RecordNotFound unless listing.publicly_visible?
      current_user.favorites.find_or_create_by!(listing: listing)
      redirect_to favorite_return_path(listing_path(listing)), notice: "Annonce ajoutée aux favoris.", status: :see_other
    end
    def destroy
      current_user.favorites.find_by!(listing_id: params[:id]).destroy!
      redirect_to favorite_return_path(account_favorites_path), status: :see_other
    end
    private

    def favorite_return_path(fallback)
      return fallback unless params[:return_to] == "catalogue"
      filters = params[:filters].is_a?(ActionController::Parameters) ? params[:filters].permit(:q, :city, :category_id, :intent, :exchange_mode, :service_location_mode, :priority, :sort, :radius, :view, :page, :max_points, category_ids: [], exchange_modes: []).to_h : {}
      listings_path(filters)
    end
  end
end
