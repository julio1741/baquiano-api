module Api
  module V1
    module Admin
      # Reuses the same phone+OTP flow as the other roles for now. The spec
      # calls for MFA on administration (section 7) but doesn't pin down the
      # mechanism (TOTP? WebAuthn?) — that's a follow-up decision, not
      # something to invent here.
      class SessionsController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::OtpAuthenticatable

        skip_before_action :authenticate!, only: :refresh

        private

        def app_type = "admin"
      end
    end
  end
end
