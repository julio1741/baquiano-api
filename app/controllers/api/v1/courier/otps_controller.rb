module Api
  module V1
    module Courier
      class OtpsController < Api::V1::BaseController
        include Api::V1::OtpAuthenticatable

        private

        def app_type = "courier"
      end
    end
  end
end
