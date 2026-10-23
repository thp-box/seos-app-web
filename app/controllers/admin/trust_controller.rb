module Admin
  class TrustController < BaseController
    before_action :require_trust_access

    def index
      @appeals = TrustAppeal.order(id: :desc).limit(30) if current_user.permission?("trust.manage")
      @events = TrustEvent.order(id: :desc).limit(50)
      @referrals = Referral.order(id: :desc).limit(30)
      @snapshots = TrustScoreSnapshot.order(id: :desc).limit(30)
    end

    def risks
      raise Pundit::NotAuthorizedError unless current_user.permission?("trust.risk")
      AuditLog.create!(actor: current_user, target: current_user, action: "trust.risk.read", reason: "Consultation de la file de revue humaine")
      @risks = TrustRiskAssessment.where("expires_at > ?", Time.current).order(id: :desc).limit(50)
    end

    def create
      raise Pundit::NotAuthorizedError unless current_user.permission?("trust.manage")
      case params[:operation]
      when "correct"
        raise Exchanges::Invalid, "Correction inconnue." unless %w[exclude restore].include?(params[:decision])
        TrustGovernance.correct!(TrustEvent.find(params[:record_id]), actor: current_user, excluded: params[:decision] == "exclude", reason: params[:reason])
      when "appeal"
        TrustGovernance.decide!(TrustAppeal.find(params[:record_id]), actor: current_user, action: params[:decision], reason: params[:reason])
      when "referral"
        referral = Referral.find(params[:record_id])
        referral.with_lock { Referrals.invalidate!(referral, current_user, params[:reason]) }
      when "restore_referral"
        TrustGovernance.restore_referral!(Referral.find(params[:record_id]), actor: current_user, reason: params[:reason])
      when "risk"
        raise Pundit::NotAuthorizedError unless current_user.permission?("trust.risk")
        raise Exchanges::Invalid, "Décision inconnue." unless %w[dismissed reviewed].include?(params[:decision])
        risk = TrustRiskAssessment.where("expires_at > ?", Time.current).find(params[:record_id])
        risk.with_lock do
          raise Exchanges::Invalid, "La revue est déjà clôturée." unless risk.status == "open"
          risk.update!(status: params[:decision], reviewed_by: current_user, decision: params[:reason])
          AuditLog.create!(actor: current_user, target: risk, action: "trust.risk.#{params[:decision]}", reason: params[:reason])
        end
      else
        raise Exchanges::Invalid, "Action inconnue."
      end
      redirect_to admin_trust_index_path, notice: "Décision enregistrée et auditée.", status: :see_other
    end

    private

    def require_trust_access
      raise Pundit::NotAuthorizedError unless %w[trust.read trust.manage trust.risk].any? { |permission| current_user.permission?(permission) }
      raise Pundit::NotAuthorizedError if action_name == "index" && !%w[trust.read trust.manage].any? { |permission| current_user.permission?(permission) }
    end
  end
end
