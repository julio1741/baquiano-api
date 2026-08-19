# Shared OTP + session mechanics for the customer/courier/merchant
# namespaces — the underlying account/session model is identical, only
# `app_type` (which the including controller must define) differs.
module Api
  module V1
    module OtpAuthenticatable
      extend ActiveSupport::Concern

      def create
        result = Identity::RequestOtp.call(
          country_code: otp_params[:phone_country_code],
          phone_number: otp_params[:phone_number],
          purpose: otp_purpose,
          ip: request.remote_ip
        )
        render json: otp_challenge_body(result), status: :created
      end

      def verify
        result = Identity::VerifyOtp.call(
          country_code: verify_params[:phone_country_code],
          phone_number: verify_params[:phone_number],
          code: verify_params[:code],
          purpose: otp_purpose,
          device_attrs: device_attrs,
          ip: request.remote_ip,
          user_agent: request.user_agent,
          first_name: verify_params[:first_name],
          last_name: verify_params[:last_name]
        )
        render json: session_body(result), status: :ok
      end

      def refresh
        result = Identity::RefreshSession.call(
          refresh_token: refresh_params[:refresh_token], ip: request.remote_ip, user_agent: request.user_agent
        )
        render json: session_body(result), status: :ok
      end

      def destroy
        Identity::RevokeSession.call(session: current_session)
        head :no_content
      end

      private

      def app_type
        raise NotImplementedError, "#{self.class} must define #app_type"
      end

      def otp_purpose
        params[:purpose].presence || "sign_in"
      end

      def otp_params
        params.permit(:phone_country_code, :phone_number)
      end

      def verify_params
        params.permit(:phone_country_code, :phone_number, :code, :first_name, :last_name)
      end

      def refresh_params
        params.permit(:refresh_token)
      end

      def device_attrs
        params.require(:device)
          .permit(:installation_id, :platform, :app_version, :os_version, :device_model, :push_token,
                  :push_provider, :fingerprint)
          .to_h.symbolize_keys.merge(app_type: app_type)
      end

      def otp_challenge_body(result)
        body = { otp_challenge_id: result.otp_challenge.id, expires_at: result.otp_challenge.expires_at }
        body[:dev_only_code] = result.dev_only_code if result.dev_only_code
        body
      end

      def session_body(result)
        user = result.respond_to?(:user) ? result.user : result.session.user
        {
          user: { id: user.id, status: user.status },
          access_token: result.access_token,
          access_token_expires_at: result.access_token_expires_at,
          refresh_token: result.refresh_token
        }
      end
    end
  end
end
