require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Domain modules live at app/domains/<domain>/{models,services,commands,
    # policies,queries,serializers,jobs,events,subscribers,validators,errors}.
    # Collapsing the second-level folder so files resolve as Orders::PlaceOrder
    # instead of Orders::Services::PlaceOrder (see config/initializers/autoloading.rb).

    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc
    config.active_job.queue_adapter = :sidekiq

    # PostGIS types (geography) and extensions don't round-trip through the
    # Ruby schema dumper, so the schema is tracked as SQL instead.
    config.active_record.schema_format = :sql

    # Every table uses a UUID primary key (see section 3 of the spec).
    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.middleware.use Rack::Attack
  end
end
