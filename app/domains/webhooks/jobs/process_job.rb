module Webhooks
  class ProcessJob < ApplicationJob
    queue_as :webhooks

    def perform(webhook_event_id)
      event = WebhookEvent.find_by(id: webhook_event_id)
      return unless event&.received?

      Webhooks::Process.call(webhook_event: event)
    rescue StandardError
      nil # already recorded on the event by Webhooks::Process; the retry job picks it back up
    end
  end
end
