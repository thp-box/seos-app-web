module NotificationsHelper
  def notification_counts
    @notification_counts ||= current_user ? current_user.notifications.unread.group(:category).count : {}
  end

  def notification_badge(category, extra_class: nil)
    category = Array(category).include?("all") ? "all" : Array(category).uniq.join(",")
    count = category == "all" ? notification_counts.values.sum : category.split(",").sum { |key| notification_counts.fetch(key, 0) }
    tag.span(count > 99 ? "99+" : count, class: [ "notification-badge", extra_class ].compact.join(" "),
      hidden: count.zero?, data: { notification_category: category }, aria: { label: "#{count} notifications non lues" })
  end

  def notification_category_for(controllers)
    mapping = { "service_requests" => "messages", "messages" => "messages", "community" => "quests", "points" => "wallet",
      "mission_applications" => "missions", "profiles" => "profile", "login_sessions" => "security",
      "notifications" => "all", "registrations" => "security" }
    key = controllers.first.split("/").last
    mapping.fetch(key, key)
  end

  def notification_destination(notice)
    return account_service_request_path(notice.service_request_id) if notice.service_request_id && %w[messages reviews].include?(notice.category)
    notification_category_path(notice.category)
  end

  def notification_category_path(category)
    {
      "messages" => account_service_requests_path, "quests" => account_community_path,
      "wallet" => account_points_path, "favorites" => account_favorites_path,
      "profile" => edit_account_profile_path, "listings" => account_listings_path,
      "reviews" => account_reviews_path, "testimonials" => account_testimonials_path,
      "chains" => account_chains_path, "trust" => account_trust_path,
      "organizations" => account_organizations_path, "missions" => account_mission_applications_path,
      "privacy" => account_privacy_path, "security" => account_login_sessions_path
    }.fetch(category) { category == "support" && FeatureFlag.support_enabled? ? account_support_path : account_notifications_path }
  end
end
