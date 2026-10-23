module Admin
  class StudioController < BaseController
    before_action { raise Pundit::NotAuthorizedError unless current_user.super_admin? }
    content_security_policy only: :preview do |policy|
      policy.frame_ancestors :self
    end

    def preview
      @studio_version = StudioVersion.find(params[:id])
      @preview_width = [ 375, 768, 1440 ].include?(params[:width].to_i) ? params[:width].to_i : 1440
      @preview_page = params[:page].presence || "home"
      raise ActiveRecord::RecordNotFound unless @studio_version.available_pages.include?(@preview_page)
      return render :preview, layout: "application" unless params[:canvas] == "1"

      @preview_width = nil
      if (@page = @studio_version.site.dig("pages", @preview_page))
        @slug = @preview_page
        render "site/show", layout: "application"
      elsif %w[communaute voyage-solidaire].include?(@preview_page)
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
    end
  end
end
