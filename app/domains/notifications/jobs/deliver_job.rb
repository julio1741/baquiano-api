module Notifications
  # No push/SMS/email gateway is wired up yet (same gap as
  # Identity::DeliverOtpJob — see docs/architecture/decisions.md). This
  # only logs that a dispatch was requested and marks the notification
  # sent, so the rest of the system (preferences, idempotency, retry
  # bookkeeping) is real and ready for a real provider to slot in later.
  class DeliverJob < ApplicationJob
    queue_as :notifications

    def perform(notification_id)
      notification = Notification.find_by(id: notification_id)
      return unless notification&.pending?

      notification.increment!(:attempt_count)
      Rails.logger.info(event: "notification_dispatch_requested", notification_id: notification.id,
                         channel: notification.channel, template_code: notification.template_code)
      notification.update!(status: "sent", sent_at: Time.current, provider_message_id: SecureRandom.uuid)
    end
  end
end
