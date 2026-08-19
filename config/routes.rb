Rails.application.routes.draw do
  # Swagger UI + the JSON it reads are dev-only tools (see Gemfile); guard
  # the mounts so test/production boots don't need those gems loaded.
  if defined?(Rswag::Ui::Engine) && defined?(Rswag::Api::Engine)
    mount Rswag::Ui::Engine => "/api-docs"
    mount Rswag::Api::Engine => "/api-docs"
  end

  # Liveness probe for load balancers / uptime monitors: 200 if the process
  # can boot and respond, regardless of dependency health.
  get "up" => "rails/health#show", as: :rails_health_check
  get "health/live", to: "health#live"

  # Readiness probe: 200 only if Postgres and Redis are reachable.
  get "health/ready", to: "health#ready"

  namespace :api do
    namespace :v1 do
      # Domain routes are added incrementally per section 6 of the spec:
      # /api/v1/customer, /api/v1/courier, /api/v1/merchant, /api/v1/admin,
      # /api/v1/webhooks.

      namespace :customer do
        post "otp", to: "otps#create"
        post "otp/verify", to: "otps#verify"
        post "session/refresh", to: "sessions#refresh"
        delete "session", to: "sessions#destroy"
        resource :profile, only: %i[show update], controller: "profiles"
      end

      namespace :courier do
        post "otp", to: "otps#create"
        post "otp/verify", to: "otps#verify"
        post "session/refresh", to: "sessions#refresh"
        delete "session", to: "sessions#destroy"
      end

      namespace :merchant do
        post "otp", to: "otps#create"
        post "otp/verify", to: "otps#verify"
        post "session/refresh", to: "sessions#refresh"
        delete "session", to: "sessions#destroy"
      end

      namespace :admin do
        post "otp", to: "otps#create"
        post "otp/verify", to: "otps#verify"
        post "session/refresh", to: "sessions#refresh"
        delete "session", to: "sessions#destroy"

        resources :roles, only: %i[index show create update destroy]
        resources :permissions, only: [ :index ]
        resources :role_assignments, only: %i[create destroy]
      end
    end
  end
end
