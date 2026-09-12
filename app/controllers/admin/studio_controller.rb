module Admin
  class StudioController < BaseController
    before_action { raise Pundit::NotAuthorizedError unless current_user.permission?("content.manage") || current_user.permission?("studio.preview") }
    def index
      @assets = StudioAsset.order(id: :desc).limit(30)
      @versions = StudioVersion.order(id: :desc).limit(30)
    end
    def create
      if params[:operation] == "upload"
        raise Pundit::NotAuthorizedError unless current_user.permission?("content.manage")
        StudioAsset.transaction do
          asset = StudioAsset.create!(author: current_user)
          SafeImage.attach!(asset.image, params[:image])
          AuditLog.create!(actor: current_user, target: asset, action: "studio.upload", reason: "Image nettoyée pour le Studio")
        end
      elsif params[:operation] == "draft"
        settings = submitted_settings
        raise Exchanges::Invalid, "Configuration JSON invalide." unless settings.is_a?(Hash)
        Studio.change!(actor: current_user, settings: settings, name: params[:name], source: StudioVersion.find_by(id: params[:source_id]), reset: params[:reset])
      else
        Studio.transition!(version: StudioVersion.find(params[:record_id]), actor: current_user, action: params[:operation], reason: params[:reason])
      end
      destination = params[:return_site_id].present? ? edit_admin_site_path(StudioVersion.find(params[:return_site_id]), area: params[:operation] == "upload" ? "images" : (params[:return_site_area] == "kit" ? "kit" : "pages")) : admin_studio_index_path
      redirect_to destination, notice: "Version enregistrée.", status: :see_other
    end
    content_security_policy only: :preview do |policy|
      policy.frame_ancestors :self
    end
    def preview
      @studio_version = StudioVersion.find(params[:id])
      @preview_width = [ 375, 768, 1440 ].include?(params[:width].to_i) ? params[:width].to_i : 1440
      @preview_page = params[:page].presence || "home"
      raise ActiveRecord::RecordNotFound unless (StudioVersion::PAGES + @studio_version.site.fetch("pages", {}).keys).include?(@preview_page)
      if params[:canvas] == "1"
        @preview_width = nil
        if (@page = @studio_version.site.dig("pages", @preview_page))
          @slug = @preview_page
          render "site/show", layout: "application"
        elsif @preview_page == "communaute"
          @slug = @preview_page
          @page = SiteDesign.default_page(@slug)
          render "site/show", layout: "application"
        elsif @preview_page == "home"
          render "pages/home", layout: "application"
        else
          @content = ContentVersion.where(id: @studio_version.settings.fetch("editorial_resets", []), slug: @preview_page).first || ContentVersion.current("page", @preview_page)
          raise ActiveRecord::RecordNotFound unless @content
          render "contents/show", layout: "application"
        end
      else
        render :preview, layout: "application"
      end
    end
    private
    def submitted_settings
      return JSON.parse(params[:settings].to_s) if params[:settings].present?
      tokens = params.fetch(:tokens, ActionController::Parameters.new).permit(*(StudioVersion::COLORS.keys + StudioVersion::OPTIONS.keys)).to_h.reject { |_key, value| value.blank? }
      pages = params.fetch(:pages, ActionController::Parameters.new).permit(**StudioVersion::PAGES.index_with { %w[title description image alt separator animated] }).to_h
      pages.transform_values! do |fields|
        fields.reject! { |_key, value| value.blank? }
        fields["animated"] = fields["animated"] == "1" if fields.key?("animated")
        fields
      end
      { "tokens" => tokens, "pages" => pages.reject { |_key, fields| fields.empty? } }
    rescue JSON::ParserError
      nil
    end
  end
end
