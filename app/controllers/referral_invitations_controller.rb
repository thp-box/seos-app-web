class ReferralInvitationsController < ApplicationController
  before_action :private_response

  def show
    link = ReferralLink.find_by!(token: params[:token])
    if user_signed_in?
      return redirect_to account_trust_path, notice: "Ce lien permet aux nouveaux membres de s’inscrire avec un parrain. Votre compte existe déjà."
    end
    unless Referrals.eligible?(link.owner)
      session.delete(:referral_link_id)
      return redirect_to new_user_registration_path, alert: "Ce lien de parrainage n’est pas disponible actuellement. Vous pouvez toujours créer votre compte."
    end
    session[:referral_link_id] = link.id
    response.headers["Referrer-Policy"] = "no-referrer"
    redirect_to new_user_registration_path
  end
end
