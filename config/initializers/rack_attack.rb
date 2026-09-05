Rails.application.config.middleware.use Rack::Attack
# A shared, expiring store is required across web workers in production.
Rack::Attack.cache.store = if Rails.env.production?
  Rails.cache
else
  ActiveSupport::Cache::MemoryStore.new
end
Rack::Attack.throttle("authentication/ip", limit: 20, period: 5.minutes) do |request|
  request.ip if request.post? && request.path.start_with?("/auth/")
end
Rack::Attack.throttled_responder = lambda do |_request|
  [ 429, { "content-type" => "text/plain; charset=utf-8", "retry-after" => "300" },
    [ "Trop de tentatives. Réessayez dans quelques minutes." ] ]
end
Rack::Attack.throttle("contact/ip", limit: 5, period: 1.hour) do |request|
  request.ip if request.post? && request.path == "/contact"
end
Rack::Attack.throttle("community/ip", limit: 40, period: 5.minutes) do |request|
  request.ip if request.post? && request.path.match?(%r{\A/compte/(echanges|commentaires|signalements)})
end
