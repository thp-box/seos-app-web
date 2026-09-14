class Missions
  def self.save!(mission:, actor:, attributes:, photos: [])
    raise Pundit::NotAuthorizedError unless (actor.super_admin? && actor.permission?("missions.manage")) || OrganizationPolicy.new(actor, mission.organization).edit_content?
    raise Exchanges::Invalid, "Une association vérifiée est nécessaire." unless mission.organization.association? && mission.organization.verified?
    mission.with_lock do
      mission.assign_attributes(attributes)
      if mission.persisted? && mission.mission_applications.where(status: %w[pending accepted]).exists? && (mission.changes.keys - %w[title description lock_version]).any?
        raise Exchanges::Invalid, "Des candidatures sont en cours : créez une autre mission pour modifier les conditions du séjour."
      end
      mission.update!(attributes.merge(status: "draft", published_at: nil))
      uploads = Array(photos).reject(&:blank?)
      raise Exchanges::Invalid, "Six photos maximum." if mission.photos.count + uploads.size > 6
      uploads.each { |photo| SafeImage.attach!(mission.photos, photo) }
      AuditLog.create!(actor: actor, target: mission, action: "mission.draft", reason: "Préparation d’une mission à revoir")
    end
    mission
  end

  def self.transition!(mission:, actor:, status:, reason:)
    case status
    when "pending_review"
      raise Pundit::NotAuthorizedError unless OrganizationPolicy.new(actor, mission.organization).edit_content?
    when "published"
      raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.permission?("missions.manage")
      raise Exchanges::Invalid, "Le Voyage solidaire est désactivé." unless FeatureFlag.voyage_enabled?
    when "paused", "archived"
      raise Pundit::NotAuthorizedError unless actor.permission?("missions.manage") || OrganizationPolicy.new(actor, mission.organization).manage_team?
    else
      raise Exchanges::Invalid, "État inconnu."
    end
    mission.with_lock do
      if %w[pending_review published].include?(status)
        mission.valid?(:publication) || raise(ActiveRecord::RecordInvalid, mission)
      end
      mission.update!(status: status, published_at: status == "published" ? Time.current : nil, published_by: status == "published" ? actor : mission.published_by)
      AuditLog.create!(actor: actor, target: mission, action: "mission.#{status}", reason: reason)
    end
  end

  def self.apply!(mission:, actor:, message:, starts_on:, ends_on:)
    Chains.active!(actor)
    mission.with_lock do
      raise Exchanges::Invalid, "Cette mission n’accepte pas de candidature." unless mission.publicly_visible?
      raise Pundit::NotAuthorizedError if mission.organization.organization_memberships.active.exists?(user: actor)
      application = mission.mission_applications.new(user: actor, message: message, starts_on: starts_on, ends_on: ends_on)
      validate_dates!(application)
      application.save!
      notify_team!(mission, "mission:application:#{application.id}", "Une nouvelle candidature est disponible dans votre espace organisation.")
      application
    end
  end

  def self.validate_dates!(application)
    mission = application.volunteer_mission
    start, finish = application.starts_on, application.ends_on
    raise Exchanges::Invalid, "Choisissez des dates dans la période de mission et respectant le séjour minimal." unless start && finish && start >= Date.current && start >= mission.starts_on && finish <= mission.ends_on && finish >= start && (finish - start).to_i + 1 >= mission.minimum_stay_days
  end

  def self.decide!(application:, actor:, status:, reason:)
    mission = application.volunteer_mission
    raise Pundit::NotAuthorizedError unless (status == "withdrawn" && application.user_id == actor.id) || application.manageable_by?(actor)
    raise Exchanges::Invalid, "Décision inconnue." unless %w[accepted rejected withdrawn].include?(status)
    mission.with_lock do
      application.reload
      return application if application.status == status
      raise Exchanges::Invalid, "Cette candidature est déjà terminée." unless %w[pending accepted].include?(application.status)
      if status == "accepted"
        raise Exchanges::Invalid, "La mission est indisponible." unless mission.publicly_visible?
        Chains.active!(application.user)
        validate_dates!(application)
        overlaps = mission.mission_applications.where(status: "accepted").where("starts_on <= ? AND ends_on >= ?", application.ends_on, application.starts_on)
        # Sweep intervals; non-overlapping stays do not consume simultaneous capacity.
        events = overlaps.flat_map { |item| [ [ item.starts_on, 1 ], [ item.ends_on + 1, -1 ] ] }
        events += [ [ application.starts_on, 1 ], [ application.ends_on + 1, -1 ] ]
        occupancy = 0
        events.group_by(&:first).sort.each do |_date, changes|
          occupancy += changes.sum(&:last)
          raise Exchanges::Invalid, "La capacité d’accueil est atteinte pour ces dates." if occupancy > mission.volunteer_capacity
        end
      end
      application.update!(status: status, decided_at: Time.current)
      AuditLog.create!(actor: actor, target: application, action: "mission.application.#{status}", reason: reason)
      Notification.notify!(user: application.user, key: "mission:decision:#{application.id}:#{AuditLog.maximum(:id)}", title: "Votre candidature a été examinée. Consultez votre espace.")
    end
  end

  def self.message!(application:, actor:, body:, key:)
    Chains.active!(actor)
    raise Pundit::NotAuthorizedError unless application.visible_to?(actor)
    application.volunteer_mission.with_lock do
      raise Exchanges::Invalid, "La conversation est fermée." unless %w[pending accepted].include?(application.reload.status) && application.volunteer_mission.publicly_visible?
      existing = application.mission_messages.find_by(user: actor, delivery_key: key)
      if existing
        raise Exchanges::Invalid, "Cette clé identifie un autre message." unless existing.body == body
        return existing
      end
      message = application.mission_messages.create!(user: actor, body: body, delivery_key: key)
      if actor.id == application.user_id
        notify_team!(application.volunteer_mission, "mission:message:#{message.id}", "Un nouveau message de candidature est disponible.")
      else
        Notification.notify!(user: application.user, key: "mission:message:#{message.id}", title: "Un nouveau message de candidature est disponible.")
      end
      message
    end
  end

  def self.notify_team!(mission, key, title)
    mission.organization.organization_memberships.active.where(role: %w[owner manager]).includes(:user).each do |membership|
      Notification.notify!(user: membership.user, key: "#{key}:#{membership.user_id}", title: title) if membership.user.active_for_authentication?
    end
  end
end
