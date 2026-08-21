module Api
  module V1
    module NotificationsActions
      extend ActiveSupport::Concern

      included do
        include Authenticatable
      end

      def index
        notifications = current_user.notifications.order(created_at: :desc)
        render json: notifications.map { |notification| notification_body(notification) }
      end

      private

      def notification_body(notification)
        {
          id: notification.id, order_id: notification.order_id, channel: notification.channel,
          template_code: notification.template_code, status: notification.status, sent_at: notification.sent_at
        }
      end
    end
  end
end
