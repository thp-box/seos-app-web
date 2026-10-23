module AccountNavigationHelper
  def account_navigation_groups
    definitions = [
      [ "Activité", [
        [ "Vue d’ensemble", account_root_path, %w[account/dashboard] ],
        [ "Mes annonces", account_listings_path, %w[account/listings] ],
        [ "Mes échanges", account_service_requests_path, %w[account/service_requests account/messages] ],
        [ "Quêtes & chaînes", account_community_path, %w[account/community account/chains] ],
        [ "Mon profil", edit_account_profile_path, %w[account/profiles] ]
      ] ],
      [ "À consulter", [
        [ "Notifications", account_notifications_path, %w[account/notifications] ],
        [ "Avis et favoris", account_reviews_path, %w[account/reviews account/favorites] ],
        [ "Points & confiance", account_points_path, %w[account/points account/trust] ],
        [ "Associations", account_organizations_path, %w[account/organizations account/mission_applications] ]
      ] ],
      [ "Réglages", [
        [ "Compte & sécurité", edit_user_registration_path, %w[users/registrations account/login_sessions] ],
        [ "Données personnelles", account_privacy_path, %w[account/privacy] ]
      ] ]
    ]
    definitions.map do |label, entries|
      { label: label, links: entries.map { |text, path, controllers| { label: text, path: path, category: notification_category_for(controllers), active: controllers.include?(controller_path) } } }
    end
  end
end
