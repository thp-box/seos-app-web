class TestimonialsController < ApplicationController
  def index
    @testimonials = Testimonial.where(status: "published", removed_at: nil).includes(:user, video_attachment: :blob).order(published_at: :desc).limit(100).select(&:publicly_visible?)
  end
end
