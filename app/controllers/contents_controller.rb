class ContentsController < ApplicationController
  def index
    @articles = ContentVersion.live.where(kind: "article").order(published_at: :desc).to_a.uniq(&:slug)
  end
  def show
    if params[:kind] == "legal"
      raise ActiveRecord::RecordNotFound unless ContentVersion::LEGAL_SLUGS.include?(params[:slug])
      return redirect_to legal_center_path(anchor: "legal-#{params[:slug]}"), status: :moved_permanently
    end
    if params[:kind] == "page" && params[:slug] == "fonctionnement"
      return redirect_to root_path(anchor: "presentation"), status: :moved_permanently
    end
    if params[:kind] == "page" && %w[don echange points].include?(params[:slug])
      @slug = params[:slug]
      @indexable = true
      @canonical = request.base_url + request.path
      @page = StudioVersion.current&.site&.dig("pages", @slug) || SiteDesign.default_page(@slug)
      return render "site/show"
    end
    @content = ContentVersion.current(params[:kind], params[:slug])
    if params[:kind] == "page" && !@content && (@page = StudioVersion.current&.site&.dig("pages", params[:slug]))
      @slug = params[:slug]
      return render "site/show"
    end
    raise ActiveRecord::RecordNotFound unless @content
    @indexable = true
    @canonical = request.base_url + request.path
    @description = @content.summary
  end
end
