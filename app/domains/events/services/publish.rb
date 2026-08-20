module Events
  # The one place that writes both sides of the transactional outbox: the
  # permanent DomainEvent record and the OutboxEvent work item a publisher
  # job will later pick up. Call this inside the same DB transaction as the
  # state change it documents, never after committing it.
  class Publish
    def self.call(aggregate:, event_type:, payload: {}, event_version: 1, causation_id: nil)
      correlation_id = Current.correlation_id || SecureRandom.uuid

      DomainEvent.create!(
        aggregate_type: aggregate.class.name,
        aggregate_id: aggregate.id,
        event_type: event_type,
        event_version: event_version,
        payload: payload,
        occurred_at: Time.current,
        correlation_id: correlation_id,
        causation_id: causation_id
      )

      OutboxEvent.create!(
        aggregate_type: aggregate.class.name,
        aggregate_id: aggregate.id,
        event_type: event_type,
        payload: payload,
        status: "pending",
        available_at: Time.current
      )
    end
  end
end
