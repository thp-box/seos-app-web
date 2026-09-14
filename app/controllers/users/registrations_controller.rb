module Users
  class RegistrationsController < Devise::RegistrationsController
    layout -> { %w[edit update].include?(action_name) ? "account" : "application" }
    before_action :private_response

    def create
      if params.dig(:user, :website).present?
        self.resource = resource_class.new(sign_up_params)
        resource.errors.add(:base, "Inscription impossible. Réessayez.")
        render :new, status: :unprocessable_content
      else
        super do |user|
          if user.persisted? && user.errors.empty?
            Referrals.register_link!(user, session.delete(:referral_link_id))
          end
        end
      end
    end

    def update
      super do |user|
        if user.errors.empty?
          user.login_sessions.active.update_all(revoked_at: Time.current)
          sign_out user
          reset_session
        end
      end
    end

    protected

    def after_update_path_for(_resource) = new_user_session_path
  end
end
