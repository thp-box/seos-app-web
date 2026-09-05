class ContentsController < ApplicationController
  def index
    @articles = ContentVersion.live.where(kind: "article").order(published_at: :desc).to_a.uniq(&:slug)
  end
  def show
    @content = ContentVersion.current(params[:kind], params[:slug])
    raise ActiveRecord::RecordNotFound unless @content
    @indexable = true
    @canonical = request.base_url + request.path
    @description = @content.summary
  end
end
