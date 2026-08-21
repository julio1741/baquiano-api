module Notifications
  # Respects NotificationPreference opt-outs before ever creating a
  # Notification row. destination (phone/email/push token) is only ever
  # digested, never stored raw — section 4.15: "No incluir datos
  # personales o detalles sensibles innecesarios en push notifications."
  class Send
    def self.call(...) = new(...).call

    def initialize(user:, channel:, template_code:, idempotency_key:, order: nil, payload: {}, destination: nil)
      @user = user
      @channel = channel
      @template_code = template_code
      @idempotency_key = idempotency_key
      @order = order
      @payload = payload
      @destination = destination
    end

    def call
      existing = Notification.find_by(user: @user, idempotency_key: @idempotency_key)
      return existing if existing
      return nil unless enabled?

      notification = Notification.create!(
        user: @user, order: @order, channel: @channel, template_code: @template_code,
        destination_digest: @destination.present? ? BlindIndex.digest(@destination) : nil, payload: @payload,
        scheduled_at: Time.current, idempotency_key: @idempotency_key
      )
      Notifications::DeliverJob.perform_later(notification.id)
      notification
    end

    private

    def enabled?
      preference = NotificationPreference.find_by(user: @user, notification_type: @template_code)
      return true unless preference

      case @channel.to_s
      when "push" then preference.push_enabled
      when "sms" then preference.sms_enabled
      when "email" then preference.email_enabled
      else true
      end
    end
  end
end
