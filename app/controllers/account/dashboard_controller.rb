module Account
  class DashboardController < BaseController
    def show
      @organizations = current_user.organizations.where(status: :verified)
        .where(organization_memberships: { status: :active })
    end
  end
end
