class MediaController < ApplicationController
  def show
    attachment = ActiveStorage::Attachment.find(params[:id])
    record = attachment.record
    allowed = case record
    when Listing then record.publicly_visible? || ListingPolicy.new(current_user, record).update?
    when Profile then Profile.visible.exists?(id: record.id) || record.user == current_user
    when Message then record.removed_at.nil? && record.service_request.participant?(current_user)
    end
    raise ActiveRecord::RecordNotFound unless allowed
    private_response
    response.headers["X-Content-Type-Options"] = "nosniff"
    send_data attachment.blob.download, type: "image/jpeg", disposition: "inline", filename: "image.jpg"
  end
end
