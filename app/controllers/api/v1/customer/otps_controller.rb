module Api
  module V1
    module Customer
      class OtpsController < Api::V1::BaseController
        include Api::V1::OtpAuthenticatable

        private

        def app_type = "customer"
      end
    end
  end
end
