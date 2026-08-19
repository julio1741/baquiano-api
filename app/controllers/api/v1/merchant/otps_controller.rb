module Api
  module V1
    module Merchant
      class OtpsController < Api::V1::BaseController
        include Api::V1::OtpAuthenticatable

        private

        def app_type = "merchant"
      end
    end
  end
end
