class Privacy
  def self.request!(user:, kind:, details:)
    Chains.active!(user)
    DataRequest.create!(user: user, kind: kind, details: details, verified_at: Time.current, response_due_at: 1.month.from_now)
  end

  def self.export!(request:, actor:)
    raise Pundit::NotAuthorizedError unless actor.id == request.user_id || actor.permission?("privacy.manage")
    raise Exchanges::Invalid, "Cette demande ne concerne pas un export." unless %w[access portability].include?(request.kind)
    request.with_lock do
      user = request.user
      payload = {
        account: user.attributes.slice("id", "email", "created_at", "status"),
        profile: user.profile&.attributes&.slice("display_name", "bio", "public_city", "skills", "languages", "phone", "address_line"),
        listings: user.listings.map { |item| item.attributes.slice("id", "title", "description", "status", "city", "address_line") },
        points: PointEntry.where(point_account: PointAccount.find_by(user: user)).map { |item| item.attributes.slice("id", "amount", "created_at") },
        messages: Message.where(sender: user).map { |item| { id: item.id, body: item.body, created_at: item.created_at } },
        mission_applications: MissionApplication.where(user: user).map { |item| { id: item.id, message: item.message, status: item.status, starts_on: item.starts_on, ends_on: item.ends_on } },
        comments: Comment.where(user: user).map { |item| item.attributes.slice("id", "body", "created_at") },
        reviews_written: Review.where(author: user).map { |item| item.attributes.slice("id", "factual_body", "completion_answer", "would_reengage", "created_at") },
        reviews_received: Review.where(reviewee: user).revealed.map { |item| item.attributes.slice("id", "factual_body", "response", "completion_answer", "created_at") },
        mission_messages: MissionMessage.where(user: user).map { |item| item.attributes.slice("id", "body", "created_at") },
        testimonials: Testimonial.where(user: user).map { |item| item.attributes.slice("id", "quote", "transcript", "display_name_snapshot", "public_location_snapshot", "consented_at", "consent_version", "status") },
        memberships: OrganizationMembership.where(user: user).map { |item| item.attributes.slice("id", "organization_id", "role", "status", "created_at") },
        rewards: PointRewardClaim.where(user: user).map { |item| item.attributes.slice("id", "kind", "status", "amount", "level", "created_at") },
        achievements: UserAchievement.where(user: user).map { |item| item.attributes.slice("id", "achievement_id", "status", "points", "created_at") },
        contributions: FinancialContribution.where(user: user).map { |item| item.attributes.slice("id", "amount_cents", "currency", "status", "created_at") },
        favorites: Favorite.where(user: user).map { |item| item.attributes.slice("listing_id", "created_at") },
        notifications: Notification.where(user: user).map { |item| item.attributes.slice("id", "title", "created_at", "read_at") },
        sessions: LoginSession.where(user: user).map { |item| item.attributes.slice("id", "user_agent_summary", "last_seen_at", "expires_at", "revoked_at") },
        requests: DataRequest.where(user: user).map { |item| { id: item.id, kind: item.kind, status: item.status, response: item.response } }
      }
      request.export_file.attach(io: StringIO.new(encryptor.encrypt_and_sign(payload.to_json)), filename: "export.enc", content_type: "application/octet-stream")
      request.update!(status: "completed", completed_at: Time.current, export_expires_at: 24.hours.from_now, response: "Export disponible pendant 24 heures. Les données des autres membres sont exclues.")
      AuditLog.create!(actor: actor, target: request, action: "privacy.export", reason: "Export temporaire des données du demandeur")
    end
  end

  def self.encryptor = ActiveSupport::MessageEncryptor.new(Rails.application.key_generator.generate_key("privacy-export-v1", 32), cipher: "aes-256-gcm")

  def self.review!(request:, actor:, response:)
    raise Pundit::NotAuthorizedError unless actor.permission?("privacy.manage") && actor.id != request.user_id
    raise Exchanges::Invalid, "Une réponse motivée est nécessaire." unless response.present? && response.size <= 3000
    request.with_lock do
      raise Exchanges::Invalid, "La demande est déjà terminée." unless %w[pending reviewed].include?(request.status)
      request.update!(status: "reviewed", reviewed_by: actor, response: response, preview: { "listings" => request.user.listings.count, "retained" => "Registres PS, preuves et conversations partagées : revue de conservation distincte, sans réécriture des écritures financières.", "at" => Time.current.iso8601 })
      AuditLog.create!(actor: actor, target: request, action: "privacy.review", reason: "Demande de droits examinée")
    end
  end

  def self.execute!(request:, actor:)
    raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.permission?("privacy.manage") && actor.id != request.user_id && actor.id != request.reviewed_by_id
    request.with_lock do
      raise Exchanges::Invalid, "Une revue récente et une seconde approbation sont nécessaires." unless request.status == "reviewed" && Time.iso8601(request.preview.fetch("at")) > 1.day.ago
      user = request.user
      if %w[erasure restriction objection].include?(request.kind)
        user.with_lock do
          user.listings.update_all(status: "removed", moderation_hold: true)
          user.profile&.update!(status: "restricted")
          Testimonial.where(user: user).find_each { |record| Community.withdraw!(record: record, user: user) }
          user.login_sessions.active.update_all(revoked_at: Time.current)
          if request.kind == "erasure"
            raise Exchanges::Invalid, "Transférez d’abord les responsabilités d’organisation et le rôle administratif." if user.administrative? || user.organization_memberships.active.where(role: "owner").exists?
            user.profile&.update!(status: "anonymized", display_name: "Ancien membre", bio: nil, public_city: nil, skills: nil, languages: nil, phone: nil, address_line: nil)
            user.profile&.avatar&.purge_later
            Comment.where(user: user).update_all(body: "Commentaire retiré", removed_at: Time.current)
            Review.where(author: user).update_all(factual_body: nil)
            Review.where(reviewee: user).update_all(response: nil)
            GoogleIdentity.where(user: user).delete_all
            Testimonial.where(user: user).find_each do |testimonial|
              testimonial.update!(quote: "Témoignage retiré", transcript: testimonial.kind == "video" ? "Contenu retiré" : nil, display_name_snapshot: "Ancien membre", public_location_snapshot: nil)
              testimonial.video.purge_later
            end
            user.listings.find_each { |listing| listing.photos.purge_later; listing.update!(title: "Annonce retirée", description: nil, address_line: nil, availability: nil, city: nil, latitude: nil, longitude: nil) }
            user.skip_reconfirmation!
            user.update!(status: "anonymized", unconfirmed_email: nil, email: "removed-#{SecureRandom.hex(16)}@deleted.invalid", password: SecureRandom.hex(32), reset_password_token: nil, confirmation_token: nil, email_notifications: false)
            %w[google stripe backups].each { |provider| request.provider_erasure_tasks.find_or_create_by!(provider: provider) }
          else
            user.update!(status: "suspended")
          end
        end
      elsif request.kind == "withdrawal"
        user.update!(email_notifications: false)
        Testimonial.where(user: user).find_each { |record| Community.withdraw!(record: record, user: user) }
      end
      request.response = "#{request.response} Effacement partiel : registres PS, preuves et conversations partagées restent soumis à une revue de conservation distincte ; propagation prestataires en attente." if request.kind == "erasure"
      request.update!(status: request.kind == "erasure" ? "partial" : "completed", approved_by: actor, completed_at: Time.current)
      AuditLog.create!(actor: actor, target: request, action: "privacy.execute", reason: "Seconde validation de la demande de droits")
    end
  end
end
