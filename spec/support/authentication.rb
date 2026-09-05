module AuthenticationHelpers
  def login(user, password: "UnMotDePasseSolide!42")
    post user_session_path, params: { user: { email: user.email, password: password } }
  end

  def grant(user, permission)
    create(:admin_permission_grant, user: user, permission: permission)
  end
end
RSpec.configure { |config| config.include AuthenticationHelpers, type: :request }
