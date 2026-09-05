module Account
  class ReviewsController < BaseController
    def create
      request = ServiceRequest.participating(current_user).find(params[:service_request_id])
      ratings = params.fetch(:ratings, ActionController::Parameters.new).permit(*ReviewCriterion.applicable(request, current_user).pluck(:id).map(&:to_s)).to_h
      ReviewSubmission.call(request: request, actor: current_user, attributes: params.require(:review).permit(:completion_answer, :would_reengage, :factual_body).to_h, ratings: ratings)
      redirect_to account_service_request_path(request), notice: "Avis enregistré. Les avis deviennent publics après les deux réponses ou 14 jours.", status: :see_other
    end
    def update
      review = Review.where(reviewee: current_user).revealed.find(params[:id])
      review.update!(response: params.require(:review).permit(:response)[:response])
      redirect_to account_service_request_path(review.service_request), notice: "Réponse enregistrée.", status: :see_other
    end
  end
end
