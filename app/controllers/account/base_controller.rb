module Account
  class BaseController < ApplicationController
    before_action :authenticate_user!
    before_action :private_response
    layout "account"
  end
end
