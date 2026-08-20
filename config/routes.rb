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

        get "coverage", to: "coverage#show"
        get "branches/:branch_id/catalog", to: "catalogs#show"

        resources :addresses, only: %i[index create update destroy]
        post "branches/:branch_id/cart", to: "carts#create"
        resources :carts, only: [ :show ] do
          resources :cart_items, only: [ :create ], path: "items"
          resources :quotes, only: [ :create ]
        end
        resources :cart_items, only: %i[update destroy]
        resources :quotes, only: [ :show ] do
          resources :orders, only: [ :create ]
        end
        resources :orders, only: %i[index show] do
          post "cancellation_request", to: "orders#request_cancellation", on: :member
        end
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

        resources :branches, only: %i[index show update] do
          member do
            post :pause
            post :resume
          end
          resources :catalogs, only: %i[index create]
          resources :inventory_items, only: %i[index create]
          resources :orders, only: [ :index ]
        end

        resources :catalogs, only: %i[show update] do
          post :publish, on: :member
          resources :categories, only: %i[index create]
          resources :products, only: %i[index create]
        end

        resources :categories, only: %i[show update destroy]
        resources :products, only: %i[show update destroy]
        resources :inventory_items, only: [ :update ]

        resources :orders, only: [ :show ] do
          member do
            post :accept
            post :reject
            post :start_preparing
            post :mark_ready
          end
        end
      end

      namespace :admin do
        post "otp", to: "otps#create"
        post "otp/verify", to: "otps#verify"
        post "session/refresh", to: "sessions#refresh"
        delete "session", to: "sessions#destroy"

        resources :roles, only: %i[index show create update destroy]
        resources :permissions, only: [ :index ]
        resources :role_assignments, only: %i[create destroy]

        resources :organizations, only: %i[index show create update destroy]
        resources :merchants, only: %i[index show create update destroy]
        resources :branches, only: %i[index show create update destroy] do
          member do
            post :pause
            post :resume
          end
        end
        resources :orders, only: %i[index show]
      end
    end
  end
end
