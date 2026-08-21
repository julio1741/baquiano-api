module Events
  # Section 8: "Procesamiento de outbox". Nothing has ever read
  # OutboxEvent.pending before this — DomainEvent/OutboxEvent were written
  # (Events::Publish) but never actually drained. No real message broker
  # is wired up (no Kafka/SQS/etc — section 16 territory), so "publishing"
  # here means what Identity::DeliverOtpJob and Notifications::DeliverJob
  # already mean elsewhere in this MVP: log that it happened and mark it
  # done, so the pattern is operationally complete and ready for a real
  # consumer to slot in later.
  class ProcessOutboxJob < ApplicationJob
    queue_as :maintenance

    def perform
      OutboxEvent.where(status: "pending").where(available_at: ..Time.current).find_each do |event|
        Rails.logger.info(event: "outbox_event_published", outbox_event_id: event.id,
                           event_type: event.event_type, aggregate_type: event.aggregate_type,
                           aggregate_id: event.aggregate_id)
        event.publish!
      rescue StandardError => e
        event.register_failure!(e.message)
      end
    end
  end
end
