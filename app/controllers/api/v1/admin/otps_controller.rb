module Api
  module V1
    module Admin
      class OtpsController < Api::V1::BaseController
        include Api::V1::OtpAuthenticatable

        private

        def app_type = "admin"
      end
    end
  end
end
