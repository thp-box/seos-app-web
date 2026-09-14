namespace :seos do
  desc "Promouvoir le premier super-admin depuis un compte confirmé (EMAIL=...)"
  task bootstrap_super_admin: :environment do
    abort "Un super-admin existe déjà. Utilisez le processus d'administration." if User.super_admin.exists?
    user = User.find_by!(email: ENV.fetch("EMAIL").strip.downcase)
    abort "Confirmez d'abord l'adresse e-mail du compte." unless user.active? && user.confirmed?
    User.transaction do
      previous = user.role
      user.update!(role: :super_admin)
      user.login_sessions.active.update_all(revoked_at: Time.current)
      AuditLog.create!(actor: user, target: user, action: "user.role_changed",
        reason: "Initialisation du premier super-administrateur par l'opérateur",
        metadata: { from: previous, to: "super_admin" })
    end
    puts "Super-administrateur initialisé. Reconnectez-vous."
  end
end
