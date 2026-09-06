class MediaController < ApplicationController
  def show
    attachment = ActiveStorage::Attachment.find(params[:id])
    record = attachment.record
    allowed = case record
    when Listing then record.publicly_visible? || ListingPolicy.new(current_user, record).update?
    when Profile then Profile.visible.exists?(id: record.id) || record.user == current_user
    when Organization then record.publicly_visible? || OrganizationPolicy.new(current_user, record).workspace? || current_user&.permission?("organizations.manage")
    when VolunteerMission then record.publicly_visible? || OrganizationPolicy.new(current_user, record.organization).workspace? || current_user&.permission?("missions.manage")
    when Partnership then record.publicly_visible? || OrganizationPolicy.new(current_user, record.organization).workspace? || current_user&.permission?("partnerships.manage")
    when UserAchievement then record.user == current_user || current_user&.permission?("community.manage")
    when Testimonial then record.publicly_visible? || record.user == current_user || current_user&.permission?("community.manage")
    when Message then record.removed_at.nil? && record.service_request.participant?(current_user)
    end
    raise ActiveRecord::RecordNotFound unless allowed
    private_response
    response.headers["X-Content-Type-Options"] = "nosniff"
    video = record.is_a?(Testimonial)
    send_data attachment.blob.download, type: video ? "video/mp4" : "image/jpeg", disposition: "inline", filename: video ? "temoignage.mp4" : "image.jpg"
  end
end
