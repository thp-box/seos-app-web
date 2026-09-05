module Account
  class CommentsController < BaseController
    def create
      listing = Listing.find_by!(slug: params[:listing_slug])
      raise ActiveRecord::RecordNotFound unless listing.publicly_visible?
      listing.comments.create!(user: current_user, body: params.require(:comment).permit(:body)[:body])
      redirect_to listing_path(listing, anchor: "comments"), status: :see_other
    end
    def destroy
      comment = Comment.where(user: current_user).find(params[:id])
      comment.update!(removed_at: Time.current)
      redirect_to listing_path(comment.listing), status: :see_other
    end
  end
end
