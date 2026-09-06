class PrivacyPreferencesController < ApplicationController
  skip_before_action :verify_login_session, only: :receipt
  before_action :private_response
  def show
    @consent = CookieConsent.where(visitor_digest: Digest::SHA256.hexdigest(cookies.signed[:privacy_visitor].to_s), version: CookieConsent::VERSION).where("expires_at > ?", Time.current).order(id: :desc).first
  end
  def receipt
    @record = DataRequest.find_signed(params[:receipt_token], purpose: :privacy_receipt) || raise(ActiveRecord::RecordNotFound)
    response.headers["Referrer-Policy"] = "no-referrer"
    render :receipt, layout: "privacy_receipt"
  end
  def create
    raise Exchanges::Invalid, "Choix inconnu." unless %w[accept reject custom].include?(params[:choice])
    token = cookies.signed[:privacy_visitor].presence || SecureRandom.hex(24)
    cookies.signed[:privacy_visitor] = { value: token, expires: 6.months.from_now, httponly: true, same_site: :lax, secure: request.ssl? }
    CookieConsent.create!(visitor_digest: Digest::SHA256.hexdigest(token), version: CookieConsent::VERSION, analytics: params[:choice] == "accept" || (params[:choice] == "custom" && params[:analytics] == "1"), external_media: params[:choice] == "accept" || (params[:choice] == "custom" && params[:external_media] == "1"), expires_at: 6.months.from_now)
    redirect_to privacy_preferences_path, notice: "Votre choix est enregistré. Vous pouvez le modifier à tout moment.", status: :see_other
  end
end
