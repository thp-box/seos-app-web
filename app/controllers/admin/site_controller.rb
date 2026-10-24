module Admin
  class SiteController < BaseController
    before_action { raise Pundit::NotAuthorizedError unless current_user.super_admin? }
    before_action :load_version, only: [ :review, :publish ]

    def index
      version = workspace_version || Studio.change!(actor: current_user, settings: {}, name: "Éditeur visuel", source: StudioVersion.current)
      redirect_to visual_admin_site_path(version, page: params[:page].presence || "home"), status: :see_other
    end

    def review
      @area = params[:area]
      @editor = params[:editor].presence_in(%w[visual builder]) || "visual"
      @slug = params[:page].presence || "home"
      raise ActiveRecord::RecordNotFound unless @version.available_pages.include?(@slug)
      @device = params[:device].presence_in(%w[phone tablet desktop]) || "desktop"
      @live_version = StudioVersion.current
      @review_errors = Studio.review_errors(@version)
    end

    def publish
      Studio.publish_from_review!(version: @version, actor: current_user, digest: params[:digest], live_id: params[:live_id])
      redirect_to admin_site_index_path(page: params[:page].presence || "home"), notice: "Vos modifications sont en ligne.", status: :see_other
    end

    private

    def workspace_version
      live = StudioVersion.current
      drafts = StudioVersion.where(author: current_user, status: %w[draft validated])
      drafts = drafts.where("created_at > ?", live.published_at) if live&.published_at
      drafts.order(id: :desc).first || live
    end

    def load_version
      @version = StudioVersion.find(params[:id])
    end
  end
end
