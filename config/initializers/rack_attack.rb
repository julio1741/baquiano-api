class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("REDIS_URL", "redis://redis:6379/0"))

  # Coarse default: caps abusive clients before any endpoint-specific limit
  # (OTP requests, login, etc.) is added in Increment 1.
  throttle("requests/ip", limit: 300, period: 1.minute) do |request|
    request.ip
  end

  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]
    headers = { "Content-Type" => "application/json" }
    headers["Retry-After"] = retry_after.to_s if retry_after

    [ 429, headers, [ { error: { code: "rate_limited", message: "Too many requests" } }.to_json ] ]
  end
end
