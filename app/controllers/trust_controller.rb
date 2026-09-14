class TrustController < ApplicationController
  def show
    redirect_to legal_center_path(anchor: "legal-securite"), status: :moved_permanently
  end
end
