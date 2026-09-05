class FinancialSupport
  def self.client
    Stripe::StripeClient.new(ENV.fetch("STRIPE_SECRET_KEY"))
  end

  def self.ready?
    ENV["FINANCIAL_SUPPORT_READY"] == "1" && ENV["STRIPE_SECRET_KEY"].present? && ENV["STRIPE_WEBHOOK_SECRET"].present? &&
      ENV["APP_URL"].to_s.match?(%r{\Ahttps://[a-zA-Z0-9.-]+(?::\d+)?\z})
  end

  def self.toggle!(actor:, enabled:, reason:, validations:)
    raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.permission?("financial.manage")
    raise Exchanges::Invalid, "Validez la recette Stripe, les informations comptables et les conditions de soutien avant activation." if enabled && (!ready? || validations != "1")
    FeatureFlag.transaction do
      flag = FeatureFlag.find_or_initialize_by(key: "financial_support_enabled")
      flag.update!(enabled: enabled)
      AuditLog.create!(actor: actor, target: flag, action: "financial.flag", reason: reason, metadata: { "to" => enabled.to_s })
    end
  end

  def self.checkout!(user:, amount:, request_key:)
    Chains.active!(user)
    raise Exchanges::Invalid, "Le soutien financier est indisponible." unless FeatureFlag.support_enabled? && ready?
    record = FinancialContribution.find_or_create_by!(user: user, request_key: request_key) { |item| item.amount_cents = amount }
    raise Exchanges::Invalid, "Cette demande possède déjà un autre montant." unless record.amount_cents == amount
    record.with_lock do
      raise Exchanges::Invalid, "Cette demande est ancienne ou déjà terminée. Consultez son suivi." unless record.status == "pending" && record.created_at > 23.hours.ago
      session = if record.stripe_session_id
        client.v1.checkout.sessions.retrieve(record.stripe_session_id)
      else
        client.v1.checkout.sessions.create({ mode: "payment", client_reference_id: record.id.to_s,
          metadata: { contribution_id: record.id.to_s }, payment_intent_data: { metadata: { contribution_id: record.id.to_s } },
          line_items: [ { price_data: { currency: "eur", unit_amount: record.amount_cents, product_data: { name: "Soutien à SEOS France" } }, quantity: 1 } ],
          success_url: "#{ENV.fetch('APP_URL')}/compte/soutien", cancel_url: "#{ENV.fetch('APP_URL')}/compte/soutien" },
          { idempotency_key: "contribution:#{record.id}" })
      end
      record.update!(stripe_session_id: session.id)
      url = URI.parse(session.url.to_s)
      raise Exchanges::Invalid, "Le paiement est indisponible. Consultez son suivi." unless url.scheme == "https" && url.host == "checkout.stripe.com" && !url.userinfo
      url.to_s
    end
  rescue Stripe::StripeError
    raise Exchanges::Invalid, "Stripe est temporairement indisponible. Réessayez cette même demande depuis son suivi."
  end

  def self.webhook!(body:, signature:)
    event = Stripe::Webhook.construct_event(body, signature, ENV.fetch("STRIPE_WEBHOOK_SECRET"))
    PaymentEvent.transaction do
      return if PaymentEvent.exists?(stripe_event_id: event.id)
      object = event.data.object
      record = if event.type.start_with?("checkout.session.")
        FinancialContribution.find_by(stripe_session_id: object.id)
      elsif event.type == "charge.refunded"
        FinancialContribution.find_by(payment_intent_id: object.payment_intent)
      end
      # A Checkout can complete before the create response reaches us.
      if !record && event.type.start_with?("checkout.session.")
        record = FinancialContribution.find_by(id: object.metadata["contribution_id"])
      end
      if record
        record.with_lock do
          if event.type.start_with?("checkout.session.")
            apply_session!(record, object)
            record.update!(status: "failed") if event.type == "checkout.session.async_payment_failed" && record.status == "pending"
          elsif event.type == "charge.refunded"
            raise Exchanges::Invalid, "Montant Stripe incohérent." unless object.amount == record.amount_cents && object.currency == record.currency
            refunded = [ record.refunded_cents, object.amount_refunded ].max
            record.update!(refunded_cents: refunded, status: refunded == record.amount_cents ? "refunded" : "partially_refunded") if refunded.positive?
          end
        end
      end
      refund_data = event.type == "charge.refunded" ? object.to_hash.slice(:payment_intent, :amount, :amount_refunded, :currency) : {}
      PaymentEvent.create!(stripe_event_id: event.id, event_type: event.type, financial_contribution: record, refund_data: refund_data)
    end
  end

  def self.apply_session!(record, session)
    raise Exchanges::Invalid, "Session Stripe incohérente." unless session.amount_total == record.amount_cents && session.currency == record.currency && session.mode == "payment" && session.client_reference_id == record.id.to_s && (!record.stripe_session_id || record.stripe_session_id == session.id)
    attrs = { stripe_session_id: session.id, payment_intent_id: session.payment_intent }
    if %w[pending failed expired].include?(record.status)
      attrs[:status] = if session.payment_status == "paid" then "paid"
      elsif session.status == "expired" then "expired"
      else record.status
      end
    end
    record.update!(attrs)
    PaymentEvent.where(event_type: "charge.refunded").where("json_extract(refund_data, '$.payment_intent') = ?", record.payment_intent_id).find_each do |event|
      data = event.refund_data
      next unless data["amount"] == record.amount_cents && data["currency"] == record.currency
      refunded = [ record.refunded_cents, data["amount_refunded"].to_i ].max
      record.update!(refunded_cents: refunded, status: refunded == record.amount_cents ? "refunded" : "partially_refunded") if refunded.positive?
    end
  end

  def self.reconcile!(record:, actor:, reason:)
    raise Pundit::NotAuthorizedError unless actor.permission?("financial.manage")
    raise Exchanges::Invalid, "Aucune session connue : rapprochez la référence locale dans Stripe avant toute nouvelle tentative." unless record.stripe_session_id
    raise Exchanges::Invalid, "Saisissez un motif de 1 à 500 caractères." unless reason.present? && reason.size <= 500
    record.with_lock do
      apply_session!(record, client.v1.checkout.sessions.retrieve(record.stripe_session_id))
      if record.payment_intent_id && record.status != "pending"
        intent = client.v1.payment_intents.retrieve(record.payment_intent_id)
        if intent.latest_charge
          charge = client.v1.charges.retrieve(intent.latest_charge)
          raise Exchanges::Invalid, "Charge Stripe incohérente." unless charge.amount == record.amount_cents && charge.currency == record.currency
          refunded = [ record.refunded_cents, charge.amount_refunded ].max
          if refunded.positive?
            record.update!(refunded_cents: refunded, status: refunded == record.amount_cents ? "refunded" : "partially_refunded")
          end
        end
      end
      AuditLog.create!(actor: actor, target: record, action: "financial.reconcile", reason: reason)
    end
  rescue Stripe::StripeError
    raise Exchanges::Invalid, "Rapprochement Stripe indisponible."
  end

  def self.refund!(record:, actor:, reason:)
    raise Pundit::NotAuthorizedError unless actor.super_admin? && actor.permission?("financial.manage")
    raise Exchanges::Invalid, "Saisissez un motif de 1 à 500 caractères." unless reason.present? && reason.size <= 500
    record.with_lock do
      record.update!(refund_requested_at: Time.current) unless record.refund_requested_at
    end
    record.with_lock do
      return record if %w[refunded refund_pending].include?(record.status)
      raise Exchanges::Invalid, "Seul un paiement encaissé et non remboursé peut être remboursé ici." unless record.status == "paid" && record.payment_intent_id && record.refunded_cents.zero?
      raise Exchanges::Invalid, "Rapprochez la tentative de remboursement ancienne avant toute action." if record.refund_requested_at && record.refund_requested_at <= 23.hours.ago
      refund = client.v1.refunds.create({ payment_intent: record.payment_intent_id }, { idempotency_key: "contribution:#{record.id}:refund" })
      raise Exchanges::Invalid, "Le remboursement a échoué. Rapprochez le paiement." unless %w[succeeded pending requires_action].include?(refund.status)
      record.update!(stripe_refund_id: refund.id, status: refund.status == "succeeded" ? "refunded" : "refund_pending", refunded_cents: refund.status == "succeeded" ? record.amount_cents : 0)
      AuditLog.create!(actor: actor, target: record, action: "financial.refund", reason: reason)
    end
  rescue Stripe::StripeError
    raise Exchanges::Invalid, "Remboursement Stripe indisponible. Rapprochez le paiement avant de réessayer."
  end
end
