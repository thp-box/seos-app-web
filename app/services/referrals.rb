class Referrals
  def self.partners(user)
    ServiceRequest.participating(user).completed.where.not(completed_at: nil).where.not(requester_confirmed_at: nil).where.not(provider_confirmed_at: nil).pluck(:requester_id, :provider_id).flatten.uniq - [ user.id ]
  end

  def self.eligible?(user)
    user.active? && user.confirmed? &&
      ((user.created_at <= 30.days.ago && partners(user).size >= 2) || ReferralExemption.where(user: user).where("expires_at > ?", Time.current).exists?)
  end

  def self.issue!(user)
    user.with_lock do
      raise Exchanges::Invalid, "Le parrainage demande 30 jours d’ancienneté et deux partenaires distincts." unless eligible?(user)
      codes = ReferralCode.where(owner: user)
      raise Exchanges::Invalid, "Cinq codes disponibles maximum, cinq émissions par jour et une par minute." if codes.available.count >= 5 || codes.where(created_at: 24.hours.ago..).count >= 5 || codes.where(created_at: 1.minute.ago..).exists?
      raw = SecureRandom.urlsafe_base64(24)
      codes.create!(code_digest: ReferralCode.digest(raw), expires_at: 7.days.from_now)
      raw
    end
  end

  def self.claim!(user, raw_codes)
    user.with_lock do
      raise Exchanges::Invalid, "Les codes sont acceptés pendant les sept premiers jours du compte." unless user.active? && user.confirmed? && user.created_at > 7.days.ago
      codes = raw_codes.to_s.split(/[\s,;]+/).reject(&:blank?)
      existing = Referral.where(referred_user: user)
      raise Exchanges::Invalid, "Saisissez de un à dix codes, issus de parrains distincts." if codes.empty? || existing.count + codes.size > 10
      codes.each do |raw|
        code = ReferralCode.available.find_by(code_digest: ReferralCode.digest(raw))
        raise Exchanges::Invalid, "Un code est indisponible ou son parrain n’est pas éligible." unless code && eligible?(code.owner)
        raise Exchanges::Invalid, "Chaque parrain doit être distinct de vous et des parrains déjà enregistrés." if code.owner_id == user.id || existing.exists?(referrer_id: code.owner_id)
        code.update!(claimed_at: Time.current)
        referral = existing.create!(referral_code: code, referrer: code.owner, position: existing.count + 1,
          primary_referrer: !existing.exists?, claimed_at: Time.current, objection_deadline_at: 72.hours.from_now)
        Notification.notify!(user: code.owner, key: "referral:#{referral.id}", title: "Un code a été utilisé. Vous disposez de 72 heures pour faire objection.")
      end
    end
  end

  def self.primary!(user, referral)
    user.with_lock do
      raise Pundit::NotAuthorizedError unless referral.referred_user_id == user.id
      raise Exchanges::Invalid, "Le choix du parrain principal est limité aux sept premiers jours et aux soutiens valides." unless user.created_at > 7.days.ago && Referral.valid_support.exists?(id: referral.id)
      Referral.where(referred_user: user).update_all(primary_referrer: false)
      referral.update!(primary_referrer: true)
    end
  end

  def self.object!(user, referral, reason)
    referral.with_lock do
      raise Pundit::NotAuthorizedError unless referral.referrer_id == user.id
      raise Exchanges::Invalid, "Le délai d’objection de 72 heures est dépassé." unless referral.status == "provisional" && referral.objection_deadline_at > Time.current
      invalidate!(referral, user, reason, status: "objected")
    end
  end

  def self.invalidate!(referral, actor, reason, status: "invalidated")
    referral.update!(status: status, invalidated_at: Time.current, invalidation_reason: reason)
    AuditLog.create!(actor: actor, target: referral, action: "referral.#{status}", reason: reason)
    Notification.notify!(user: referral.referred_user, key: "referral:#{referral.id}:#{status}", title: "Un soutien a été retiré. Vous pouvez demander une revue humaine dans votre espace confiance.")
  end

  def self.mature!
    Referral.valid_support.find_each do |referral|
      referral.with_lock do
        next unless %w[provisional confirmed].include?(referral.status)
        referral.update!(status: "confirmed", confirmed_at: Time.current) if referral.status == "provisional" && referral.objection_deadline_at <= Time.current
        user = referral.referred_user
        sponsors = Referral.where(referred_user: user).pluck(:referrer_id)
        if referral.status == "confirmed" && referral.primary_referrer? && referral.qualified_at.nil? && user.active? && user.confirmed? && user.created_at <= 30.days.ago && (partners(user) - sponsors).size >= 2
          referral.update!(qualified_at: Time.current)
          # Eligibility only; the points job rechecks it and credits the sponsor's lifetime quest.
          Notification.notify!(user: referral.referrer, key: "referral:#{referral.id}:qualified", title: "Parrainage qualifié. La récompense est examinée par le registre Points Services.")
        end
      end
    end
  end
end
