module Api
  module V1
    module Customer
      class ProfilesController < Api::V1::BaseController
        include Authenticatable

        def show
          authorize current_user
          render json: profile_body(current_user)
        end

        def update
          authorize current_user
          current_user.update!(profile_params)
          render json: profile_body(current_user)
        end

        private

        def profile_params
          params.permit(:first_name, :last_name, :preferred_language, :timezone, :email)
        end

        def profile_body(user)
          {
            id: user.id,
            first_name: user.first_name,
            last_name: user.last_name,
            email: user.email,
            preferred_language: user.preferred_language,
            timezone: user.timezone,
            status: user.status,
            phone_verified_at: user.phone_verified_at
          }
        end
      end
    end
  end
end
