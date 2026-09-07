module Admin
  class SiteController < BaseController
    before_action { raise Pundit::NotAuthorizedError unless current_user.super_admin? }
    before_action :load_version, only: [ :edit, :update, :kit, :review, :publish ]
    content_security_policy only: :kit do |policy|
      policy.frame_ancestors :self
    end
    def index
      @area = params[:area] == "kit" ? "kit" : "pages"
      @versions = StudioVersion.order(id: :desc).limit(30)
      @workspace_version = workspace_version
      @pages = (StudioVersion::PAGES + (@workspace_version&.site&.fetch("pages", {}) || {}).keys).uniq
    end
    def new_page
      @workspace_version = workspace_version
    end
    def create
      if params[:operation] == "create_page"
        title = params[:title].to_s.strip
        raise Exchanges::Invalid, "Indiquez un nom de page (100 caractères maximum)." unless title.size.between?(1, 100)
        source = params[:source_id].present? ? StudioVersion.find(params[:source_id]) : workspace_version
        data = source&.site&.deep_dup || {}
        pages = data["pages"] ||= {}
        base = title.parameterize.first(60).presence || "page"
        base = "page-#{base}" unless base.match?(/\A[a-z]/)
        slug = base
        number = 2
        while (StudioVersion::PAGES + pages.keys).include?(slug)
          slug = "#{base}-#{number}"
          number += 1
        end
        block = { "id" => SecureRandom.uuid, "template" => "text", "values" => { "title" => title, "body" => "" } }
        pages[slug] = { "title" => title, "blocks" => [ block ] }
        version = Studio.change!(actor: current_user, source: source, name: "Modifications du site", settings: { "site" => data })
        return redirect_to edit_admin_site_path(version, page: slug, section: block["id"]), notice: "Votre page est créée. Ajoutez son contenu ; elle n’est pas encore visible sur le site.", status: :see_other
      end
      source = params[:source_id].present? ? StudioVersion.find(params[:source_id]) : StudioVersion.current
      version = Studio.change!(actor: current_user, settings: {}, name: params[:name].presence || "Mon site — #{Time.current.strftime('%d/%m %H:%M')}", source: source)
      redirect_to edit_admin_site_path(version, page: params[:page], area: params[:area] == "kit" ? "kit" : "pages"), status: :see_other
    end
    def edit
      @area = %w[pages header footer kit images].include?(params[:area]) ? params[:area] : "pages"
      @slug = params[:page].presence || "home"
      @page = @version.site.fetch("pages", {})[@slug] || SiteDesign.default_page(@slug)
      @section = @page["blocks"].find { |block| block["id"] == params[:section] } if params[:section].present?
      raise ActiveRecord::RecordNotFound if params[:section].present? && !@section
      @assets = StudioAsset.includes(image_attachment: :blob).order(id: :desc)
    end
    def update
      data = @version.site.deep_dup
      tokens = nil
      case params[:operation]
      when "page"
        slug = params[:page].to_s
        raise Exchanges::Invalid, "Adresse invalide" unless slug.match?(/\A[a-z][a-z0-9-]{0,70}\z/)
        data["pages"] ||= {}
        page = data["pages"][slug] ||= SiteDesign.default_page(slug)
        page["title"] = params[:title] if params.key?(:title)
        edit_blocks(page)
      when "chrome"
        area = params[:area]
        raise Exchanges::Invalid, "Zone inconnue" unless %w[header footer].include?(area)
        fields = params.require(:chrome).permit(:logo, :alt, :title, :description, :mobile_join_label, :join_label, :login_label, :account_label).to_h
        fields = fields.slice(*SiteDesign::CHROME.fetch(area).keys)
        fields["links"] = params.fetch(:links, ActionController::Parameters.new).permit(**12.times.to_h { |i| [ i.to_s, %w[label url] ] }).to_h.values.map { |link| link.slice("label", "url") }.reject { |link| link.values.all?(&:blank?) }
        data[area] = fields
      when "tokens"
        tokens = params.require(:tokens).permit(*(StudioVersion::COLORS.keys + StudioVersion::OPTIONS.keys)).to_h.reject { |_key, value| value.blank? }
      when "reset"
        case params[:area]
        when "header", "footer" then data.delete(params[:area])
        when "pages" then data.fetch("pages", {}).delete(params[:page])
        when "kit" then tokens = {}
        else raise Exchanges::Invalid, "Retour au défaut inconnu"
        end
      else raise Exchanges::Invalid, "Action inconnue"
      end
      settings = { "site" => data }
      settings["tokens"] = tokens if tokens
      # Each save is a new immutable proposal ancestry; a validated version is never edited.
      version = Studio.change!(actor: current_user, source: @version, settings: settings, name: @version.name, reset: (params[:area] == "kit" ? "tokens" : "pages.#{params[:page]}" if params[:operation] == "reset" && %w[kit pages].include?(params[:area])))
      destination = params[:after_save] == "review" ? review_admin_site_path(version, area: params[:area], page: params[:page]) : edit_admin_site_path(version, area: params[:area], page: params[:page])
      redirect_to destination, notice: "Modifications enregistrées. Elles seront visibles après la mise en ligne.", status: :see_other
    end
    def review
      @area = %w[pages header footer kit images].include?(params[:area]) ? params[:area] : "pages"
      @slug = params[:page].presence || "home"
      raise ActiveRecord::RecordNotFound unless (StudioVersion::PAGES + @version.site.fetch("pages", {}).keys).include?(@slug)
      @device = %w[phone tablet desktop].include?(params[:device]) ? params[:device] : "desktop"
      @live_version = StudioVersion.current
      @review_errors = Studio.review_errors(@version)
    end
    def publish
      Studio.publish_from_review!(version: @version, actor: current_user, digest: params[:digest], live_id: params[:live_id])
      redirect_to admin_site_index_path(area: params[:area] == "kit" ? "kit" : "pages"), notice: "Vos modifications sont en ligne. Les visiteurs peuvent maintenant les voir.", status: :see_other
    end
    def kit
      @kit_page = params[:page].presence || "home"
      raise ActiveRecord::RecordNotFound unless SiteDesign.reference["kit"].key?(@kit_page)
      @studio_version = @version
      render layout: "studio_kit"
    end
    private
    def workspace_version
      live = StudioVersion.current
      drafts = StudioVersion.where(author: current_user, status: %w[draft validated])
      drafts = drafts.where("created_at > ?", live.published_at) if live
      drafts.order(id: :desc).first || live
    end
    def load_version
      @version = StudioVersion.find(params[:id])
    end
    def edit_blocks(page)
      blocks = page.fetch("blocks")
      if params[:template].present?
        raise Exchanges::Invalid, "Section inconnue" unless SiteDesign.templates.key?(params[:template])
        blocks << { "id" => SecureRandom.uuid, "template" => params[:template], "values" => {} }
      end
      return unless params[:block_id].present?
      index = blocks.index { |block| block["id"] == params[:block_id] }
      raise Exchanges::Invalid, "Section introuvable" unless index
      block = blocks[index]
      case params[:block_action]
      when "remove" then blocks.delete_at(index)
      when "up" then blocks.insert([ index - 1, 0 ].max, blocks.delete_at(index))
      when "down" then blocks.insert([ index + 1, blocks.size - 1 ].min, blocks.delete_at(index))
      when "duplicate" then blocks.insert(index + 1, block.deep_dup.merge("id" => SecureRandom.uuid))
      when "save"
        block["values"] = params.fetch(:values, ActionController::Parameters.new).permit(*SiteDesign.templates.fetch(block["template"])["fields"].keys).to_h
        if block["template"] == "text"
          if block["values"]["label"].blank? && block["values"]["url"].blank?
            block["values"].except!("label", "url")
          elsif block["values"]["label"].blank? || block["values"]["url"].blank?
            raise Exchanges::Invalid, "Pour ajouter un bouton, indiquez son texte et l’adresse de la page à ouvrir. Sinon, laissez les deux champs vides."
          end
        end
        block["hidden"] = params[:hidden] == "1"
        block["separator"] = params[:separator] if params.key?(:separator)
        block["placement"] = params[:placement] if params.key?(:placement)
      else raise Exchanges::Invalid, "Action de section inconnue"
      end
    end
  end
end
