module Account
  class TestimonialsController < BaseController
    def show
      @testimonials = Testimonial.where(user: current_user).order(id: :desc).limit(20)
    end

    def create
      case params[:operation]
      when "testimonial"
        Community.testimonial!(user: current_user, attributes: params.permit(:kind, :quote, :transcript, :display_name_snapshot, :public_location_snapshot).to_h, consent: params[:consent], video: params[:video])
      when "withdraw_testimonial"
        Community.withdraw!(record: Testimonial.find(params[:record_id]), user: current_user)
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to account_testimonials_path, notice: "Votre demande a été enregistrée.", status: :see_other
    end
  end
end
