module AccountNavigationHelper
  def account_navigation_groups
    groups = [
      [ "Profil et notifications", [
        [ "Mon profil", edit_account_profile_path, %w[account/profiles] ],
        [ "Notifications", account_notifications_path, %w[account/notifications] ]
      ] ],
      [ "Annonces et échanges", [
        [ "Mes annonces", account_listings_path, %w[account/listings] ],
        [ "Mes échanges", account_service_requests_path, %w[account/service_requests account/messages] ],
        [ "Avis reçus", account_reviews_path, %w[account/reviews] ],
        [ "Mes favoris", account_favorites_path, %w[account/favorites] ]
      ] ],
      [ "Entraide et points", [
        [ "Mes quêtes", account_community_path, %w[account/community] ],
        [ "Mes témoignages", account_testimonials_path, %w[account/testimonials] ],
        [ "Mes chaînes d’entraide", account_chains_path, %w[account/chains] ],
        [ "Mon portefeuille", account_points_path, %w[account/points] ],
        [ "Confiance et parrainage", account_trust_path, %w[account/trust] ]
      ] ],
      [ "Organisations et voyage", [
        [ "Mes organisations", account_organizations_path, %w[account/organizations] ],
        [ "Mes candidatures Voyage", account_mission_applications_path, %w[account/mission_applications] ]
      ] ],
      [ "Sécurité et confidentialité", [
        [ "Mes sessions", account_login_sessions_path, %w[account/login_sessions] ],
        [ "Mes identifiants", edit_user_registration_path, %w[users/registrations] ],
        [ "Mes données et mes droits", account_privacy_path, %w[account/privacy] ]
      ] ]
    ]
    if FeatureFlag.support_enabled?
      groups[2][1] << [ "Soutenir SEOS", account_support_path, %w[account/support] ]
    end
    groups.map do |label, entries|
      { label: label, links: entries.map do |text, path, controllers|
        { label: text, path: path, active: controllers.include?(controller_path) }
      end }
    end
  end
end
