module Account
  class FavoritesController < BaseController
    def index
      @listings = current_user.favorites.includes(listing: [ :category, { user: :profile } ]).map(&:listing).select(&:publicly_visible?)
    end
    def create
      listing = Listing.find_by!(slug: params[:listing_slug])
      raise ActiveRecord::RecordNotFound unless listing.publicly_visible?
      current_user.favorites.find_or_create_by!(listing: listing)
      redirect_to listing_path(listing), notice: "Annonce ajoutée aux favoris.", status: :see_other
    end
    def destroy
      current_user.favorites.find_by!(listing_id: params[:id]).destroy!
      redirect_to account_favorites_path, status: :see_other
    end
  end
end
