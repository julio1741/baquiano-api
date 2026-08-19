# Restrictive by default: only the origins listed in CORS_ORIGINS (comma
# separated) are allowed. The merchant/admin web clients and the future
# public site will be added here per environment; the Flutter apps talk to
# the API natively and are not affected by CORS. With no origins configured
# the middleware is not mounted at all, so cross-origin browser requests are
# denied by default rather than falling back to a permissive rule.
allowed_origins = ENV.fetch("CORS_ORIGINS", "").split(",").map(&:strip).reject(&:empty?)

if allowed_origins.any?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(*allowed_origins)

      resource "/api/*",
        headers: :any,
        methods: %i[get post put patch delete options head],
        expose: %w[X-Request-Id X-Correlation-Id]
    end
  end
end
