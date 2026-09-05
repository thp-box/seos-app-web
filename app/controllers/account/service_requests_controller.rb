module Account
  class ServiceRequestsController < BaseController
    before_action :set_request, only: [ :show, :update ]
    def index
      scope = ServiceRequest.participating(current_user).includes(:listing)
      scope = scope.where(status: params[:status]) if ServiceRequest.statuses.key?(params[:status])
      scope = scope.where(params[:box] == "received" ? { provider_id: current_user.id } : { requester_id: current_user.id }) if %w[sent received].include?(params[:box])
      @requests = scope.order(updated_at: :desc).limit(100)
    end
    def create
      listing = Listing.find_by!(slug: params[:listing_slug])
      request = Exchanges.create!(listing: listing, actor: current_user)
      redirect_to account_service_request_path(request), notice: "Demande envoyée.", status: :see_other
    end
    def show
      @messages = @request.messages.where(removed_at: nil).includes(:sender).order(:created_at)
      @messages.where.not(sender: current_user).where(read_at: nil).update_all(read_at: Time.current)
      @events = @request.request_events.order(:created_at)
      @criteria = ReviewCriterion.applicable(@request, current_user)
      @reviews = @request.reviews.includes(:review_ratings).select { |review| review.author_id == current_user.id || review.revealed? }
    end
    def update
      terms = params.fetch(:terms, ActionController::Parameters.new).permit(:scheduled_at, :location, :mode, :points, :consideration).to_h.symbolize_keys
      Exchanges.transition!(request: @request, actor: current_user, action: params[:event], version: params[:agreement_version], terms: terms, reason: params[:reason])
      redirect_to account_service_request_path(@request), notice: "Échange mis à jour.", status: :see_other
    end
    private
    def set_request
      @request = ServiceRequest.participating(current_user).find(params[:id])
    end
  end
end
