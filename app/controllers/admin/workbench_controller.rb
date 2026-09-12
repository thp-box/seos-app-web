module Admin
  class WorkbenchController < BaseController
    RESOURCES = {
      "categories" => [ Category, "categories.manage" ], "restrictions" => [ CategoryRestriction, "categories.manage" ],
      "annonces" => [ Listing, "listings.moderate" ], "profils" => [ Profile, "listings.moderate" ],
      "echanges" => [ ServiceRequest, "exchanges.support" ], "signalements" => [ Report, "reports.manage" ],
      "contenus" => [ ContentVersion, "content.manage" ], "contacts" => [ ContactRequest, "reports.manage" ]
    }.freeze
    before_action :resource_access
    def index
      @records = @model.order(id: :desc).limit(100)
    end
    def new
      raise Pundit::NotAuthorizedError unless %w[categories restrictions contenus].include?(@kind)
      @record = @model.new
      if params[:from].present? && @kind == "contenus"
        source = @model.find(params[:from])
        @record.assign_attributes(source.attributes.slice("kind", "slug", "title", "summary", "body", "decorations"))
      end
    end
    def create
      raise Pundit::NotAuthorizedError unless %w[categories restrictions contenus].include?(@kind)
      @record = @model.new(attributes)
      @record.created_by = current_user if @kind == "restrictions"
      if @kind == "contenus"
        @record.author = current_user
        @record.version = (ContentVersion.where(kind: @record.kind, slug: @record.slug).maximum(:version) || 0) + 1
      end
      @model.transaction do
        @record.save!
        audit!(@record, "created")
        apply_restrictions if @kind == "restrictions"
      end
      redirect_to admin_workbench_path(@record.id, kind: @kind), notice: "Enregistrement créé.", status: :see_other
    end
    def show
      @record = @model.find(params[:id])
    end
    def update
      @record = @model.find(params[:id])
      @model.transaction do
        case @record
        when Category, CategoryRestriction
          @record.update!(attributes)
          apply_restrictions
        when Listing
          desired = params[:status]
          raise Exchanges::Invalid, "Statut non autorisé" unless %w[pending_review paused removed published].include?(desired)
          @record.valid?(:moderated_publication) || (raise ActiveRecord::RecordInvalid, @record) if desired == "published"
          @record.update!(status: desired, moderation_hold: desired != "published", published_at: (@record.published_at || (Time.current if desired == "published")), removed_at: desired == "removed" ? Time.current : nil)
          Notification.notify!(user: @record.user, key: "listing:#{@record.id}:#{@record.lock_version}", title: "Le statut de votre annonce a été examiné.", category: "listings")
        when Profile
          raise Exchanges::Invalid, "Statut non autorisé" unless %w[restricted published].include?(params[:status])
          @record.update!(status: params[:status])
          Notification.notify!(user: @record.user, key: "profile:#{@record.id}:#{@record.updated_at.to_f}", title: "La visibilité de votre profil a été examinée.", category: "profile")
        when ContentVersion
          raise Pundit::NotAuthorizedError unless current_user.super_admin?
          raise Exchanges::Invalid, "Créez une nouvelle version pour modifier un contenu publié" if @record.published_at
          @record.update!(published_at: params[:published_at].presence || Time.current)
        when Report
          moderate_report
        when ContactRequest
          @record.update!(status: "resolved", resolved_at: Time.current)
        else
          raise Pundit::NotAuthorizedError
        end
        audit!(@record, "updated")
      end
      redirect_to admin_workbench_path(@record.id, kind: @kind), notice: "Modification enregistrée et auditée.", status: :see_other
    end
    def reveal
      @record = @model.find(params[:id])
      if @record.is_a?(Profile)
        raise Pundit::NotAuthorizedError unless current_user.super_admin?
      elsif @record.is_a?(ServiceRequest)
        raise Pundit::NotAuthorizedError unless current_user.permission?("reports.manage")
        report = Report.where.not(status: "resolved").find(params[:report_id])
        target = report.reportable
        raise Pundit::NotAuthorizedError unless target == @record || (target.is_a?(Message) && target.service_request_id == @record.id)
      elsif !@record.is_a?(ContactRequest)
        raise Pundit::NotAuthorizedError
      end
      audit!(@record, "sensitive_reveal")
      @revealed = true
      render :show
    end
    private
    def resource_access
      @kind = params[:kind]
      @model, permission = RESOURCES.fetch(@kind) { raise ActiveRecord::RecordNotFound }
      raise Pundit::NotAuthorizedError unless current_user.permission?(permission)
    end
    def attributes
      fields = case @kind
      when "categories" then [ :name, :slug, :parent_id, :position, :active, :sensitive ]
      when "restrictions" then [ :category_id, :term, :reason, :starts_at, :ends_at, :active, :existing_action, :lock_version ]
      when "contenus" then [ :kind, :slug, :title, :summary, :body, { decorations: [] } ]
      else []
      end
      params.require(:record).permit(*fields)
    end
    def audit!(record, event)
      AuditLog.create!(actor: current_user, target: record, action: "#{@kind}.#{event}", reason: params[:reason])
    end
    def apply_restrictions
      Listing.published.includes(:category).find_each do |listing|
        restriction = CategoryRestriction.effective.find { |item| item.matches?(listing) }
        next unless restriction || !listing.category.publishable?
        previous = listing.status
        listing.update!(status: restriction&.existing_action == "pause" ? "paused" : "pending_review", moderation_hold: true)
        AuditLog.create!(actor: current_user, target: listing, action: "listing.restricted", reason: params[:reason], metadata: { from: previous, to: listing.status })
        Notification.notify!(user: listing.user, key: "restriction:#{listing.id}:#{listing.lock_version}", title: "Une annonce a été mise en revue")
      end
    end
    def moderate_report
      target = @record.reportable
      case params[:decision]
      when "hide", "restore"
        case target
        when Listing
          target.update!(status: params[:decision] == "hide" ? "paused" : "pending_review", moderation_hold: true)
        when Comment, Message, Review
          target.update!(removed_at: params[:decision] == "hide" ? Time.current : nil)
        when Profile
          target.update!(status: params[:decision] == "hide" ? "restricted" : "published")
        else
          raise Exchanges::Invalid, "Cette cible requiert une médiation"
        end
      when "invalidate_review"
        raise Exchanges::Invalid, "La cible doit être un avis" unless target.is_a?(Review)
        target.update!(invalidated_at: Time.current)
      when "resolve", "assign"
      else
        raise Exchanges::Invalid, "Décision inconnue"
      end
      @record.update!(assigned_to: current_user, status: params[:decision] == "assign" ? "investigating" : "resolved",
        resolved_at: params[:decision] == "assign" ? nil : Time.current, resolution: params[:reason])
      Notification.notify!(user: @record.reporter, key: "report:#{@record.id}:#{@record.updated_at.to_f}", title: "Votre signalement a été traité")
    end
  end
end
