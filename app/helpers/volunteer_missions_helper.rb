module VolunteerMissionsHelper
  def studio_public_missions
    return [] unless FeatureFlag.voyage_enabled?
    scope = VolunteerMission.where(status: "published").where("ends_on >= ?", Date.current).joins(:organization).where(organizations: { status: "verified", kind: "association" }).includes(:organization).order(:starts_on)
    scope = scope.where(country_code: params[:country].to_s.upcase) if params[:country].present?
    scope.limit(100).select(&:publicly_visible?)
  end
end
