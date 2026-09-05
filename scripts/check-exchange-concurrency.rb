# Run only against a fresh, disposable SQLite database (see README).
abort "Use a disposable test database named seos-concurrency-*" unless Rails.env.test? && ENV.fetch("DATABASE_URL", "").include?("seos-concurrency-")
abort "The test database must have no users" if User.exists?

def simultaneously(*actors, &operation)
  ready, start = Queue.new, Queue.new
  threads = actors.map do |actor|
    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ready << true
        start.pop
        operation.call(actor)
      end
    end
  end
  actors.size.times { ready.pop }
  actors.size.times { start << true }
  threads.map(&:value)
end

people = %w[provider requester].map do |name|
  user = User.create!(email: "#{name}@concurrency.test", password: "DisposableTestPassword!42", confirmed_at: Time.current, status: :active, email_notifications: false)
  Profile.create!(user: user, display_name: name.capitalize, status: :published)
  user
end
provider, requester = people
category = Category.create!(name: "Test", slug: "test")
listing = Listing.create!(user: provider, category: category, title: "Entraide", description: "Un service à distance", service_location_mode: :remote, status: :published, published_at: Time.current)
requests = simultaneously(requester, requester) { |actor| Exchanges.create!(listing: Listing.find(listing.id), actor: actor) }
raise "Duplicate service requests" unless requests.map(&:id).uniq.size == 1 && ServiceRequest.count == 1
request = requests.first
Exchanges.transition!(request: request, actor: provider, action: "accept")
Exchanges.transition!(request: request, actor: provider, action: "propose", terms: { scheduled_at: 1.day.from_now.iso8601, location: "Appel", mode: "remote" })
Exchanges.transition!(request: request, actor: requester, action: "agree", version: 1)
simultaneously(provider, requester) { |actor| Exchanges.transition!(request: ServiceRequest.find(request.id), actor: actor, action: "confirm") }
raise "Lost confirmation" unless request.reload.completed? && request.request_events.where(kind: "confirm").count == 2
simultaneously(requester, requester) { |actor| Exchanges.message!(request: ServiceRequest.find(request.id), actor: actor, body: "Message unique", key: "same-delivery") }
raise "Duplicate message or notification" unless Message.count == 1 && Notification.where(event_key: "message:#{Message.first.id}").count == 1
puts "SQLite concurrence : demande unique, deux confirmations conservées, message et notification uniques."

admin = User.create!(email: "admin@concurrency.test", password: "DisposableTestPassword!42", role: :super_admin, confirmed_at: Time.current, status: :active)
ReferralExemption.create!(user: admin, granted_by: admin, reason: "Fixture de concurrence", expires_at: 1.day.from_now)
raw = Referrals.issue!(admin)
claims = simultaneously(provider, requester) do |actor|
  Referrals.claim!(User.find(actor.id), raw)
  :claimed
rescue Exchanges::Invalid
  :rejected
end
raise "Referral code claimed twice" unless claims.sort == [ :claimed, :rejected ] && Referral.count == 1
claimant = Referral.first.referred_user
10.times do |index|
  sponsor = User.create!(email: "sponsor#{index}@concurrency.test", password: "DisposableTestPassword!42", confirmed_at: Time.current, status: :active)
  ReferralExemption.create!(user: sponsor, granted_by: admin, reason: "Fixture de concurrence", expires_at: 1.day.from_now)
  token = Referrals.issue!(sponsor)
  if index < 8
    Referrals.claim!(claimant, token)
  else
    (@final_tokens ||= []) << token
  end
end
claims = simultaneously(*@final_tokens) do |token|
  Referrals.claim!(User.find(claimant.id), token)
  :claimed
rescue Exchanges::Invalid
  :rejected
end
raise "Eleventh referral accepted" unless claims.sort == [ :claimed, :rejected ] && Referral.where(referred_user: claimant).count == 10
raise "Multiple primary sponsors" unless Referral.where(referred_user: claimant, primary_referrer: true).count == 1
TrustAlgorithmVersion.create!(version: "concurrency", status: "active", configuration: TrustAlgorithmVersion::DEFAULT_CONFIGURATION, explanation: "Fixture isolée", created_by: admin)
simultaneously(claimant, claimant) { |actor| TrustRecalculationJob.perform_now(actor.id) }
raise "Duplicate trust snapshot" unless TrustScoreSnapshot.where(user: claimant).count == 1
puts "SQLite concurrence : code à usage unique, dix soutiens maximum, un principal, snapshot idempotent."
