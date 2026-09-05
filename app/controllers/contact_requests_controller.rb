class ContactRequestsController < ApplicationController
  def new
    @contact = ContactRequest.new
  end
  def create
    @contact = ContactRequest.new(params.require(:contact_request).permit(:email, :subject, :message))
    if params[:website].present?
      return redirect_to contact_path, notice: "Votre demande a été reçue.", status: :see_other
    end
    if @contact.save
      redirect_to contact_path, notice: "Votre demande a été transmise à l’équipe SEOS.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end
end
