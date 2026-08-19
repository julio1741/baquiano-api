source "https://rubygems.org"

ruby "3.3.12"

gem "rails", "~> 8.1.3", ">= 8.1.3.1"

# Postgres + PostGIS
gem "pg", "~> 1.5"
gem "activerecord-postgis-adapter", "~> 11.1"
gem "rgeo-geojson", "~> 2.2"

gem "puma", "~> 8.0"

# Redis-backed cache, Sidekiq for async jobs (required by spec over Solid Queue/Cache)
gem "redis", "~> 5.3"
gem "sidekiq", "~> 8.1"

gem "bootsnap", require: false

# Authorization policies per domain
gem "pundit", "~> 2.4"

# Pagination for API list endpoints
gem "pagy", "~> 9.0"

# JSON serializers
gem "blueprinter", "~> 1.1"

# Rate limiting (IP / user / device / endpoint), backed by Redis
gem "rack-attack", "~> 6.7"

# CORS for the Flutter/PWA clients
gem "rack-cors", "~> 2.0"

# Structured JSON logs without leaking framework noise
gem "lograge", "~> 0.14"

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec", "~> 3.0", require: false

  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails", "~> 6.4"
  gem "faker", "~> 3.4"
  gem "shoulda-matchers", "~> 6.4"

  gem "rswag-specs", "~> 2.16"
end

group :development do
  gem "rswag-api", "~> 2.16"
  gem "rswag-ui", "~> 2.16"
end

group :test do
  gem "simplecov", "~> 0.22", require: false
end
