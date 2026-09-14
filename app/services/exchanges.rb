class Exchanges
  class Invalid < StandardError; end
  def self.create!(listing:, actor:)
    listing.with_lock do
      raise Invalid, "Cette annonce n’est plus disponible" unless listing.publicly_visible?
      raise Invalid, "Vous ne pouvez pas répondre à votre propre annonce" if listing.user_id == actor.id
      raise Invalid, "La prise de contact est bloquée" if UserBlock.between?(actor.id, listing.user_id)
      existing = listing.service_requests.where(requester: actor, status: %w[pending accepted scheduled awaiting_confirmation disputed]).first
      return existing if existing && existing.current_status != "expired"
      existing&.update!(status: :expired)
      request = listing.service_requests.create!(requester: actor, provider: listing.user, expires_at: 14.days.from_now)
      record!(request, actor, "created", "Demande envoyée")
      request
    end
  end

  def self.transition!(request:, actor:, action:, version: nil, terms: {}, reason: nil)
    raise Pundit::NotAuthorizedError unless request.participant?(actor)
    request.with_lock do
      side = request.side(actor)
      raise Invalid, "Cette demande a expiré" if request.current_status == "expired"
      case action
      when "accept", "decline"
        raise Pundit::NotAuthorizedError unless actor.id == request.provider_id
        require_status!(request, "pending")
        raise Invalid, "L’annonce est fermée" unless request.listing.publicly_visible?
        raise Invalid, "La prise de contact est bloquée" if request.blocked?
        request.status = action == "accept" ? "accepted" : "declined"
      when "propose"
        require_status!(request, "accepted", "scheduled")
        raise Invalid, "La prise de contact est bloquée" if request.blocked?
        date = Time.zone.parse(terms[:scheduled_at].to_s) rescue nil
        raise Invalid, "Choisissez une date future et un lieu ou moyen de réalisation" unless date && date > Time.current && terms[:location].present?
        mode = terms[:mode].to_s
        raise Invalid, "Mode de réalisation invalide" unless %w[in_person remote hybrid].include?(mode)
        points = Integer(terms[:points], exception: false)
        raise Invalid, "Le montant doit être un entier positif" if request.listing.exchange_mode_points? && (!points || !(1..999_999).cover?(points))
        raise Invalid, "Cet échange ne prévoit pas de points" if !request.listing.exchange_mode_points? && terms[:points].present?
        raise Invalid, "Précisez les compétences échangées" if request.listing.exchange_mode_barter? && terms[:consideration].blank?
        request.agreement = { "scheduled_at" => date.iso8601, "location" => terms[:location].to_s.first(200), "mode" => mode, "points" => points, "consideration" => terms[:consideration].to_s.first(500) }
        request.agreement["exchange_mode"] = request.listing.exchange_mode
        if request.listing.exchange_mode_points?
          valuation = PointRuleVersion.current("valuation") || raise(Invalid, "Un barème indicatif doit être publié avant un accord en points.")
          payer, payee = request.listing.intent_offer? ? [ request.requester_id, request.provider_id ] : [ request.provider_id, request.requester_id ]
          request.agreement.merge!("payer_id" => payer, "payee_id" => payee, "valuation_version_id" => valuation.id)
        end
        request.agreement_version += 1
        request.proposed_by = actor
        request.requester_agreed_at = request.provider_agreed_at = nil
        request.requester_shared_at = request.provider_shared_at = nil
        request.public_send("#{side}_agreed_at=", Time.current)
        request.status = "accepted"
      when "agree"
        require_status!(request, "accepted")
        raise Invalid, "Cet accord a changé ; relisez-le avant de confirmer" unless request.agreement_version.positive? && version.to_i == request.agreement_version
        raise Invalid, "La prise de contact est bloquée" if request.blocked?
        request.public_send("#{side}_agreed_at=", Time.current)
        request.status = "scheduled" if request.agreed?
      when "confirm"
        return request if request.completed? && request.public_send("#{side}_confirmed_at")
        require_status!(request, "scheduled", "awaiting_confirmation")
        raise Invalid, "L’accord doit être accepté par les deux participants" unless request.agreed?
        if request.agreement["points"].present?
          raise Invalid, "Relisez le montant et confirmez la version actuelle de l’accord." unless version.to_i == request.agreement_version && request.agreement["exchange_mode"] == "points"
        end
        return request if request.public_send("#{side}_confirmed_at")
        request.public_send("#{side}_confirmed_at=", Time.current)
        request.status = "awaiting_confirmation"
        if request.requester_confirmed_at && request.provider_confirmed_at
          request.status = "completed"
          request.completed_at = Time.current
        end
      when "cancel", "dispute"
        require_status!(request, "pending", "accepted", "scheduled", "awaiting_confirmation")
        raise Invalid, "Indiquez un motif" if reason.blank? || reason.length > 1000
        request.status = action == "cancel" ? "cancelled" : "disputed"
        request.requester_shared_at = request.provider_shared_at = nil
      when "share", "revoke"
        require_status!(request, "scheduled", "awaiting_confirmation")
        raise Invalid, "Votre profil n’autorise pas le partage" if action == "share" && (actor.profile&.phone_sharing_policy != "per_exchange" || request.blocked?)
        request.public_send("#{side}_shared_at=", action == "share" ? Time.current : nil)
      else
        raise Invalid, "Action inconnue"
      end
      request.save!
      Points::Settlement.call!(request, actor: actor) if action == "confirm" && request.completed? && request.agreement["points"].present?
      details = action == "propose" ? request.agreement.to_json : reason
      record!(request, actor, action, details)
      if action == "dispute"
        Report.create!(reporter: actor, reportable: request, reason: "Litige sur un échange", details: reason)
      end
      request
    end
  end

  def self.message!(request:, actor:, body:, key:, upload: nil)
    raise Pundit::NotAuthorizedError unless request.participant?(actor)
    request.with_lock do
      raise Invalid, "La conversation est bloquée" if request.blocked?
      raise Invalid, "La conversation est fermée" if %w[cancelled declined expired].include?(request.current_status)
      existing = Message.find_by(sender: actor, delivery_key: key)
      if existing
        raise Invalid, "Identifiant d’envoi déjà utilisé" unless existing.service_request_id == request.id
        return existing
      end
      message = request.messages.create!(sender: actor, body: body, delivery_key: key)
      SafeImage.attach!(message.attachment, upload) if upload.present?
      Notification.notify!(user: request.other(actor), key: "message:#{message.id}", title: "Nouveau message dans votre échange", request: request)
      message
    end
  end

  def self.record!(request, actor, kind, details = nil)
    event = request.request_events.create!(actor: actor, kind: kind, details: details)
    Notification.notify!(user: request.other(actor), key: "exchange:#{event.id}", title: "Votre échange a été mis à jour", request: request)
  end
  def self.require_status!(request, *statuses)
    raise Invalid, "Cette action n’est plus disponible" unless statuses.include?(request.status)
  end
  private_class_method :require_status!
end
