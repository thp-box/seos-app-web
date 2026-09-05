module Account
  class ListingsController < BaseController
    before_action :set_listing, only: [ :edit, :update, :transition ]
    def index
      @listings = current_user.listings.order(updated_at: :desc)
    end
    def new
      @listing = current_user.listings.build(organization: organization_context)
      @step, @categories = 1, Category.available
      render :edit
    end
    def create
      @listing = current_user.listings.build(organization: organization_context)
      update
    end
    def edit
      @step = params[:step].to_i.clamp(1, 4)
      @categories = Category.available
    end
    def update
      raise Exchanges::Invalid, "Cette annonce est clôturée ou retirée" if @listing.closed? || @listing.removed?
      step = params[:step].to_i.clamp(1, 4)
      fields = {
        1 => %i[intent exchange_mode estimated_points category_id service_location_mode],
        2 => %i[title description city address_line availability priority],
        3 => [], 4 => []
      }.fetch(step)
      values = params.fetch(:listing, ActionController::Parameters.new).permit(*fields, :lock_version)
      @listing.assign_attributes(values)
      @listing.wizard_step = [ @listing.wizard_step, [ step + 1, 4 ].min ].max
      @listing.status = :draft if @listing.published? || @listing.pending_review?
      if @listing.save
        uploads = Array(params.dig(:listing, :photos)).reject(&:blank?)
        raise Exchanges::Invalid, "Quatre photos maximum" if @listing.photos.count + uploads.size > 4
        uploads.each { |upload| SafeImage.attach!(@listing.photos, upload) }
        redirect_to edit_account_listing_path(@listing, step: [ step + 1, 4 ].min), notice: "Brouillon enregistré.", status: :see_other
      else
        @step, @categories = step, Category.available
        render :edit, status: :unprocessable_entity
      end
    end
    def transition
      raise Exchanges::Invalid, "Confirmez que les informations publiques ne contiennent pas de coordonnées privées" if params[:event] == "publish" && params[:privacy_confirmed] != "1"
      ListingWorkflow.call(listing: @listing, actor: current_user, action: params[:event])
      redirect_to account_listings_path, notice: "Annonce mise à jour.", status: :see_other
    end
    private
    def organization_context
      return if params[:organization_slug].blank?
      organization = Organization.find_by!(slug: params[:organization_slug], kind: "association", status: "verified")
      raise Pundit::NotAuthorizedError unless organization.organization_memberships.active.exists?(user: current_user)
      organization
    end
    def set_listing
      @listing = Listing.find_by!(slug: params[:id])
      authorize @listing, :update?
    end
  end
end
