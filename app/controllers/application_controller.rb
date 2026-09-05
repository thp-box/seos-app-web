class ApplicationController < ActionController::Base
  include Pundit::Authorization
  allow_browser versions: :modern
  before_action :verify_login_session
  before_action :private_response, if: :devise_controller?
  helper_method :current_login_session
  rescue_from Pundit::NotAuthorizedError, with: :forbidden

  rescue_from Exchanges::Invalid, ActiveRecord::RecordInvalid, ActiveRecord::StaleObjectError, ActiveRecord::RecordNotUnique, with: :invalid_operation

  private

  def invalid_operation(error)
    @error_message = case error
    when ActiveRecord::RecordInvalid then error.record.errors.full_messages.join(". ")
    when ActiveRecord::StaleObjectError then "Ces informations ont changé. Rechargez la page avant de réessayer."
    when ActiveRecord::RecordNotUnique then "Cet enregistrement existe déjà. Rechargez la page pour le retrouver."
    else error.message
    end
    private_response
    render "errors/invalid_operation", status: :unprocessable_entity
  end

  def current_login_session
    @current_login_session ||= current_user&.login_sessions&.active&.find_by(
      token_digest: Digest::SHA256.hexdigest(session[:login_token].to_s))
  end

  def verify_login_session
    return unless user_signed_in?
    unless current_user.active_for_authentication? && current_login_session
      sign_out current_user
      reset_session
      redirect_to new_user_session_path, alert: "Votre session a expiré. Reconnectez-vous.", status: :see_other
      return
    end
    current_login_session.update!(last_seen_at: Time.current) if current_login_session.last_seen_at < 5.minutes.ago
  end

  def private_response
    response.headers["Cache-Control"] = "no-store"
    response.headers["X-Robots-Tag"] = "noindex, nofollow"
  end

  def require_recent_authentication
    return if current_login_session.recently_authenticated?
    redirect_to new_account_reauthentication_path, alert: "Confirmez votre mot de passe pour continuer.", status: :see_other
  end

  def forbidden
    private_response
    render "errors/forbidden", status: :forbidden
  end

  def after_sign_in_path_for(_resource) = account_root_path
end
