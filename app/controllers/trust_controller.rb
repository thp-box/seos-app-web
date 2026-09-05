class TrustController < ApplicationController
  def show
    @version = TrustAlgorithmVersion.find_by(status: "active")
  end
end
