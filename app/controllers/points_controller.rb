class PointsController < ApplicationController
  def show
    @valuation = PointRuleVersion.current("valuation")
    @engagement = PointRuleVersion.current("engagement")
    if params[:cents].present? && @valuation
      @estimate = @valuation.estimate(Integer(params[:cents], exception: false))
    end
  end
end
