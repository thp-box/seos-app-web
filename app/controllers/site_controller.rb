class SiteController < ApplicationController
  def show
    @slug = params[:slug]
    return redirect_to root_path(anchor: "presentation"), status: :moved_permanently if @slug == "fonctionnement"
    @page = StudioVersion.current&.site&.fetch("pages", {})&.[](@slug)
    @page ||= SiteDesign.default_page(@slug) if @slug == "communaute"
    raise ActiveRecord::RecordNotFound unless @page
    @indexable = true
    @canonical = request.base_url + request.path
    @description = @page["title"]
  end
end
