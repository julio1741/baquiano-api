module Api
  module V1
    module NotificationPreferencesActions
      extend ActiveSupport::Concern

      included do
        include Authenticatable
      end

      def index
        preferences = current_user.notification_preferences
        render json: preferences.map { |preference| preference_body(preference) }
      end

      def update
        preference = current_user.notification_preferences.find_or_initialize_by(
          notification_type: params[:notification_type]
        )
        preference.assign_attributes(preference_params)
        preference.save!
        render json: preference_body(preference)
      end

      private

      def preference_params
        params.permit(:push_enabled, :sms_enabled, :email_enabled)
      end

      def preference_body(preference)
        {
          id: preference.id, notification_type: preference.notification_type,
          push_enabled: preference.push_enabled, sms_enabled: preference.sms_enabled,
          email_enabled: preference.email_enabled
        }
      end
    end
  end
end
