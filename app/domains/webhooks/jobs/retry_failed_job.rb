module Webhooks
  # Section 8: "Reintentos de webhooks". Catches whatever ProcessJob
  # (enqueued right after receipt) never got to — a worker crash left it
  # stuck at "received", or an earlier attempt marked it "failed".
  class RetryFailedJob < ApplicationJob
    queue_as :maintenance

    def perform
      WebhookEvent.where(status: %w[received failed]).find_each do |event|
        Webhooks::Process.call(webhook_event: event)
      rescue StandardError
        next
      end
    end
  end
end
