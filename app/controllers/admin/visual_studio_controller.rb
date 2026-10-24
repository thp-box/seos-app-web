module Admin
  class VisualStudioController < BaseController
    before_action { raise Pundit::NotAuthorizedError unless current_user.super_admin? }
    before_action { @source = StudioVersion.find(params[:id]) }
    before_action :allow_builder_inline_styles, only: :builder
    content_security_policy only: :preview do |policy|
      policy.frame_ancestors :self
    end
    content_security_policy only: :builder do |policy|
      policy.style_src :self, :unsafe_inline
      policy.img_src :self, :data, :blob
      policy.frame_src :self, :blob
    end

    def show
      @version = @source
      @slug = params[:page].presence || "home"
      raise ActiveRecord::RecordNotFound unless @source.available_pages.include?(@slug)
      @assets = StudioAsset.includes(image_attachment: :blob).order(id: :desc)
      @editor_data = {
        settings: editable_settings, page: @slug, area: params[:area], digest: @source.digest,
        pages: StudioVersion::PAGES.to_h { |slug| [ slug, SiteDesign.default_page(slug) ] },
        templates: SiteDesign.editable_templates.to_h { |key, template| [ key, { name: helpers.site_section_name(key), description: helpers.site_section_description(key), fields: template["fields"], groups: key == "text" ? text_groups(template) : SiteSectionEditor.new(template).groups } ] },
        images: helpers.site_image_options(@assets), colors: StudioVersion::COLORS, colorNames: SiteHelper::COLOR_NAMES,
        options: StudioVersion::OPTIONS.to_h { |key, values| [ key, { label: helpers.site_token_label(key), choices: helpers.site_token_choices(key, values) } ] },
        chrome: SiteDesign::CHROME, styles: SiteSectionStyle::OPTIONS, presets: ContentVersion::PRESETS
      }
      render layout: "studio_visual"
    end

    def builder
      @version = @source
      @slug = params[:page].presence || "home"
      raise ActiveRecord::RecordNotFound unless @source.available_pages.include?(@slug)
      assets = StudioAsset.includes(image_attachment: :blob).order(id: :desc)
      page = @source.site.dig("pages", @slug) || SiteDesign.default_page(@slug)
      canvas = builder_canvas_for(page, @slug)
      @builder_data = {
        settings: editable_settings,
        page: @slug,
        digest: @source.digest,
        pages: @source.available_pages.to_h { |slug| [ slug, @source.site.dig("pages", slug) || SiteDesign.default_page(slug) ] },
        templates: builder_templates,
        images: helpers.site_image_options(assets),
        tokens: StudioVersion::OPTIONS.to_h { |key, values| [ key, { label: helpers.site_token_label(key), choices: helpers.site_token_choices(key, values) } ] },
        colors: StudioVersion::COLORS,
        colorNames: SiteHelper::COLOR_NAMES,
        options: StudioVersion::OPTIONS.to_h { |key, values| [ key, { label: helpers.site_token_label(key), choices: helpers.site_token_choices(key, values) } ] },
        chrome: SiteDesign::CHROME,
        styles: SiteSectionStyle::OPTIONS,
        presets: ContentVersion::PRESETS,
        initialHtml: canvas.fetch("html"),
        initialCss: canvas.fetch("css", ""),
        stylesheets: [ helpers.stylesheet_path("application") ],
        save: builder_save_admin_site_path(@source),
        review: review_admin_site_path(@source),
        preview: preview_admin_studio_path(@source, page: @slug, canvas: "1")
      }
      render layout: "studio_builder"
    end

    def preview
      @studio_version = proposal
      @visual_preview = true
      @visual_revision = params[:revision].to_s.first(20)
      @slug = params[:page].presence || "home"
      raise ActiveRecord::RecordNotFound unless @studio_version.available_pages.include?(@slug)
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
      render json: { digest: version.digest, url: visual_admin_site_path(version), preview: visual_preview_admin_site_path(version), save: visual_save_admin_site_path(version), review: review_admin_site_path(version) }
    rescue ActiveRecord::RecordInvalid, Exchanges::Invalid => error
      render json: { error: error.message }, status: :unprocessable_content
    end

    def builder_save
      draft = proposal
      raise Exchanges::Invalid, "Cette copie a changé. Rechargez le Studio V2 avant d’enregistrer." unless params[:digest] == @source.digest
      version = Studio.change!(actor: current_user, source: @source, name: "Composition Studio V2", settings: draft.settings.slice("site", "tokens"))
      render json: {
        digest: version.digest,
        url: builder_admin_site_path(version),
        save: builder_save_admin_site_path(version),
        preview: preview_admin_studio_path(version, page: params[:page].presence || "home", canvas: "1"),
        review: review_admin_site_path(version)
      }
    rescue ActiveRecord::RecordInvalid, Exchanges::Invalid => error
      render json: { error: error.message }, status: :unprocessable_content
    end

    private

    def allow_builder_inline_styles
      request.content_security_policy_nonce_directives = %w[script-src]
    end

    def editable_settings
      settings = @source.settings.deep_dup
      settings.dig("site", "pages")&.each_value do |page|
        page["blocks"]&.reject! { |block| SiteDesign::RETIRED_TEMPLATES.include?(block["template"]) }
      end
      settings
    end

    def text_groups(template)
      fields = template["fields"].map { |key, field| field.merge("key" => key) }
      { "Contenu" => fields.first(2), "Bouton facultatif" => fields.last(2).map { |field| field.merge("label" => field["key"] == "label" ? "Texte du bouton" : "Page à ouvrir au clic", "help" => "Laissez le texte et l’adresse vides pour ne pas afficher de bouton.") } }
    end

    def proposal
      raw = params[:document].to_s
      raise Exchanges::Invalid, "Cette page est trop volumineuse." if raw.bytesize > 2.megabytes
      document = JSON.parse(raw)
      raise Exchanges::Invalid, "Le contenu de la copie est invalide." unless document.is_a?(Hash) && (document.keys - %w[site tokens pages editorial_resets]).empty?
      document.dig("site", "pages")&.each_value do |page|
        next unless page.is_a?(Hash) && page["canvas"].is_a?(Hash)
        page["canvas"] = {
          "version" => 1,
          "html" => SiteCanvasDocument.sanitize_html(page.dig("canvas", "html")),
          "css" => SiteCanvasDocument.sanitize_css(page.dig("canvas", "css"))
        }
      end
      settings = @source.settings.merge(document.slice("site", "tokens"))
      StudioVersion.new(author: current_user, name: "Aperçu privé", settings: settings).tap(&:validate!)
    rescue JSON::ParserError
      raise Exchanges::Invalid, "Le contenu de la copie est illisible."
    end

    def builder_canvas_for(page, slug)
      @studio_version = @source
      @visual_preview = true
      if page["canvas"].present?
        content = SiteCanvasDocument.sanitize_html(page.dig("canvas", "html"))
        css = SiteCanvasDocument.sanitize_css(page.dig("canvas", "css"))
      else
        rendered = render_to_string(partial: "site/page", locals: { page: page, slug: slug })
        fragment = Nokogiri::HTML5.fragment(rendered)
        css = fragment.css("style").map(&:text).join("\n")
        fragment.css("style,.site-edit-link").remove
        content = (fragment.at_css(".maquette-surface") || fragment).to_html
      end
      header = render_to_string(partial: "shared/header")
      footer = render_to_string(partial: "shared/footer")
      html = %(<div data-studio-chrome="header">#{header}</div>#{content}<div data-studio-chrome="footer">#{footer}</div>)
      { "version" => 1, "html" => html, "css" => css }
    end

    def builder_templates
      SiteDesign.editable_templates.to_h do |key, template|
        values = template.fetch("fields").transform_values { |field| field["default"].to_s }
        block = { "id" => "preset-#{key}", "template" => key, "values" => values }
        markup =
          if key == "spacer"
            '<div class="studio-spacer" style="min-height:96px"></div>'
          elsif key == "text"
            '<section class="section"><div class="container"><h2>Votre titre</h2><p>Votre contenu</p><a class="btn btn-deep" href="/contact">En savoir plus</a></div></section>'
          else
            helpers.maquette_html(template.fetch("html", ""), block: block).to_s
          end
        [ key, { name: helpers.site_section_name(key), description: helpers.site_section_description(key), html: markup } ]
      end
    end
  end
end
