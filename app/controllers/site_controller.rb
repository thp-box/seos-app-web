class SiteController < ApplicationController
  def show
    @slug = params[:slug]
    @page = StudioVersion.current&.site&.fetch("pages", {})&.[](@slug)
    raise ActiveRecord::RecordNotFound unless @page
    @indexable = true
    @canonical = request.base_url + request.path
    @description = @page["title"]
  end
end
