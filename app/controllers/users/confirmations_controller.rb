module Users
  class ConfirmationsController < Devise::ConfirmationsController
    def show
      super
      response.status = :unprocessable_content if resource.errors.any?
    end
  end
end
