module Api
  module V1
    module Customer
      class SessionsController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::OtpAuthenticatable

        skip_before_action :authenticate!, only: :refresh

        private

        def app_type = "customer"
      end
    end
  end
end
