module Account
  class ListingsController < BaseController
    layout -> { %w[new create edit update].include?(action_name) ? "application" : "account" }
    before_action :set_listing, only: [ :edit, :update, :transition ]
    def index
      @listings = current_user.listings.order(updated_at: :desc)
    end
    def new
      @listing = current_user.listings.build(organization: organization_context, city: current_user.profile&.public_city, address_line: current_user.profile&.address_line)
      @step, @categories = 1, Category.available
      render :edit
    end
    def create
      @listing = current_user.listings.build(organization: organization_context, city: current_user.profile&.public_city, address_line: current_user.profile&.address_line)
      update
    end
    def edit
      @step = params[:step].to_i.clamp(1, 4)
      @categories = Category.available
      if @step == 3 && @listing.title.blank? && @listing.description.blank?
        @listing.title = @listing.intent_offer? ? "Cours de guitare pour débutant" : "Un coup de main pour apprendre la guitare"
        @listing.description = @listing.intent_offer? ? "Je propose des séances conviviales pour découvrir les premiers accords, à votre rythme. Nous choisissons ensemble un morceau adapté à votre niveau." : "Je cherche une personne patiente pour apprendre les premiers accords de guitare. Je débute et souhaite pratiquer régulièrement."
        @listing.availability ||= "Le mercredi ou le samedi, à convenir ensemble"
      end
    end
    def update
      raise Exchanges::Invalid, "Cette annonce est clôturée ou retirée" if @listing.closed? || @listing.removed?
      step = params[:step].to_i.clamp(1, 4)
      fields = {
        1 => %i[intent],
        2 => %i[exchange_mode estimated_points],
        3 => %i[title description category_id service_location_mode city address_line availability priority], 4 => []
      }.fetch(step)
      values = params.fetch(:listing, ActionController::Parameters.new).permit(*fields, :lock_version)
      @listing.assign_attributes(values)
      @listing.wizard_step = [ @listing.wizard_step, [ step + 1, 4 ].min ].max
      @listing.status = :draft if @listing.published? || @listing.pending_review?
      uploads = step == 3 ? Array(params.dig(:listing, :photos)).reject(&:blank?) : []
      @listing.valid?
      @listing.errors.add(:estimated_points, "doit être renseigné pour les Points Services") if step == 2 && @listing.exchange_mode_points? && @listing.estimated_points.blank?
      if step == 3
        %i[title description category].each { |field| @listing.errors.add(field, "doit être renseigné") if @listing.public_send(field).blank? }
        @listing.errors.add(:city, "doit être renseignée pour un service sur place") if !@listing.service_location_mode_remote? && @listing.city.blank?
      end
      @listing.errors.add(:photos, "quatre photos maximum") if @listing.photos.count + uploads.size > 4
      if @listing.errors.empty? && @listing.save
        uploads.each { |upload| SafeImage.attach!(@listing.photos, upload) }
        redirect_to edit_account_listing_path(@listing, step: [ step + 1, 4 ].min), status: :see_other
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
