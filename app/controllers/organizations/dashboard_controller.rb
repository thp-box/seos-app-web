module Organizations
  class DashboardController < Account::BaseController
    after_action :verify_authorized
    def show
      @organization = Organization.find_by!(slug: params[:organization_slug])
      authorize @organization
    end

    def team
      @organization = Organization.find_by!(slug: params[:organization_slug])
      authorize @organization, :team?
      @memberships = @organization.organization_memberships.active.order(:id)
    end
  end
end
