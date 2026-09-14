class GoogleIdentity < ApplicationRecord
  belongs_to :user
  validates :uid, presence: true, uniqueness: true
  validates :user_id, uniqueness: true
  def self.enabled? = ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  def self.resolve!(auth:, user: nil)
    raise Exchanges::Invalid, "Identité Google non vérifiée." unless auth && auth["provider"] == "google_oauth2" && auth["uid"].present? && auth.dig("info", "email_verified") == true
    identity = find_by(uid: auth["uid"])
    if user
      raise Pundit::NotAuthorizedError unless user.active_for_authentication?
      raise Exchanges::Invalid, "Cette identité est déjà liée." if identity && identity.user_id != user.id
      return (identity || create!(user: user, uid: auth["uid"])).user
    end
    if identity
      raise Pundit::NotAuthorizedError unless identity.user.active_for_authentication?
      return identity.user
    end
    raise Exchanges::Invalid, "Connectez-vous d’abord à votre compte SEOS pour lier Google. Pour un nouveau compte, inscrivez-vous et confirmez votre adresse."
  end
end
