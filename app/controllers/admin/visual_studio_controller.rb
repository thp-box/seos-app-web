module Admin
  class VisualStudioController < BaseController
    before_action { raise Pundit::NotAuthorizedError unless current_user.super_admin? }
    before_action { @source = StudioVersion.find(params[:id]) }
    content_security_policy only: :preview do |policy|
      policy.frame_ancestors :self
    end

    def show
      @version = @source
      @slug = params[:page].presence || "home"
      raise ActiveRecord::RecordNotFound unless (StudioVersion::PAGES + @source.site.fetch("pages", {}).keys).include?(@slug)
      @assets = StudioAsset.includes(image_attachment: :blob).order(id: :desc)
      @editor_data = {
        settings: @source.settings, page: @slug, area: params[:area], digest: @source.digest,
        pages: StudioVersion::PAGES.to_h { |slug| [ slug, SiteDesign.default_page(slug) ] },
        templates: SiteDesign.templates.to_h { |key, template| [ key, { name: helpers.site_section_name(key), fields: template["fields"], groups: key == "text" ? text_groups(template) : SiteSectionEditor.new(template).groups } ] },
        images: helpers.site_image_options(@assets), colors: StudioVersion::COLORS, colorNames: SiteHelper::COLOR_NAMES,
        options: StudioVersion::OPTIONS.to_h { |key, values| [ key, { label: helpers.site_token_label(key), choices: helpers.site_token_choices(key, values) } ] },
        chrome: SiteDesign::CHROME, styles: SiteSectionStyle::OPTIONS, presets: ContentVersion::PRESETS
      }
      render layout: "studio_visual"
    end

    def preview
      @studio_version = proposal
      @visual_preview = true
      @visual_revision = params[:revision].to_s.first(20)
      @slug = params[:page].presence || "home"
      raise ActiveRecord::RecordNotFound unless (StudioVersion::PAGES + @studio_version.site.fetch("pages", {}).keys).include?(@slug)
      @page = @studio_version.site.dig("pages", @slug)
      if @page
        render "site/show", layout: "application"
      elsif @slug == "home"
        render "pages/home", layout: "application"
      else
        @content = ContentVersion.where(id: @studio_version.settings.fetch("editorial_resets", []), slug: @slug).first || ContentVersion.current("page", @slug)
        if @content
          render "contents/show", layout: "application"
        else
          @page = SiteDesign.default_page(@slug)
          render "site/show", layout: "application"
        end
      end
    rescue ActiveRecord::RecordInvalid, Exchanges::Invalid => error
      render plain: error.message, status: :unprocessable_content
    end

    def save
      draft = proposal
      raise Exchanges::Invalid, "Cette copie a changé. Rechargez le Studio avant d’enregistrer." unless params[:digest] == @source.digest
      version = Studio.change!(actor: current_user, source: @source, name: "Modifications visuelles du site", settings: draft.settings.slice("site", "tokens"))
      render json: { digest: version.digest, url: visual_admin_site_path(version), preview: visual_preview_admin_site_path(version), save: visual_save_admin_site_path(version), review: review_admin_site_path(version), guided: edit_admin_site_path(version) }
    rescue ActiveRecord::RecordInvalid, Exchanges::Invalid => error
      render json: { error: error.message }, status: :unprocessable_content
    end

    private

    def text_groups(template)
      fields = template["fields"].map { |key, field| field.merge("key" => key) }
      { "Contenu" => fields.first(2), "Bouton facultatif" => fields.last(2).map { |field| field.merge("label" => field["key"] == "label" ? "Texte du bouton" : "Page à ouvrir au clic", "help" => "Laissez le texte et l’adresse vides pour ne pas afficher de bouton.") } }
    end

    def proposal
      raw = params[:document].to_s
      raise Exchanges::Invalid, "Cette page est trop volumineuse." if raw.bytesize > 2.megabytes
      document = JSON.parse(raw)
      raise Exchanges::Invalid, "Le contenu de la copie est invalide." unless document.is_a?(Hash) && (document.keys - %w[site tokens pages editorial_resets]).empty?
      settings = @source.settings.merge(document.slice("site", "tokens"))
      StudioVersion.new(author: current_user, name: "Aperçu privé", settings: settings).tap(&:validate!)
    rescue JSON::ParserError
      raise Exchanges::Invalid, "Le contenu de la copie est illisible."
    end
  end
end
