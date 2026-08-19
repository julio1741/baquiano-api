class Rack::Attack
  Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("REDIS_URL", "redis://redis:6379/0"))

  # Coarse default so any endpoint has a ceiling even before a more specific
  # throttle below applies.
  throttle("requests/ip", limit: 300, period: 1.minute) do |request|
    request.ip
  end

  # OTP request/verify are the two endpoints anti-enumeration and
  # brute-force protection matter most for (section 7 of the spec). This is
  # the per-IP backstop against a single client hammering many phone
  # numbers; per-phone protection regardless of IP is already handled at
  # the application layer (Identity::RequestOtp's resend interval, keyed on
  # phone_digest, not IP — a Rack::Attack rule can't cheaply key on the
  # phone number here since JSON bodies aren't parsed at this layer).
  throttle("otp-requests/ip", limit: 10, period: 15.minutes) do |request|
    request.ip if request.post? && request.path.match?(%r{\A/api/v1/\w+/otp\z})
  end

  throttle("otp-verify/ip", limit: 20, period: 15.minutes) do |request|
    request.ip if request.post? && request.path.match?(%r{\A/api/v1/\w+/otp/verify\z})
  end

  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]
    headers = { "Content-Type" => "application/json" }
    headers["Retry-After"] = retry_after.to_s if retry_after

    [ 429, headers, [ { error: { code: "rate_limited", message: "Too many requests" } }.to_json ] ]
  end
end
