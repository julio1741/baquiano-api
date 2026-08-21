module Webhooks
  # No per-provider payload processor exists yet (no real provider is
  # wired up — section 16), so this is currently a log-only placeholder,
  # same philosophy as Events::ProcessOutboxJob. What's real: the
  # attempt-tracking and failed/processed state transitions a genuine
  # processor would need, so wiring one in later doesn't require touching
  # the retry/attempt-counting machinery.
  class Process
    def self.call(...) = new(...).call

    def initialize(webhook_event:)
      @webhook_event = webhook_event
    end

    def call
      Rails.logger.info(event: "webhook_event_processed", webhook_event_id: @webhook_event.id,
                         provider: @webhook_event.provider, event_type: @webhook_event.event_type)
      @webhook_event.update!(status: "processed", processed_at: Time.current)
    rescue StandardError => e
      @webhook_event.update!(status: "failed", attempt_count: @webhook_event.attempt_count + 1, last_error: e.message)
      raise
    end
  end
end
