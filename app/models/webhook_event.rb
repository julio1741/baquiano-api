class WebhookEvent < ApplicationRecord
  encrypts :payload_encrypted

  alias_attribute :payload, :payload_encrypted

  enum :status, { received: "received", processed: "processed", failed: "failed" }, validate: true

  validates :provider, :provider_event_id, :received_at, presence: true
  validates :provider_event_id, uniqueness: { scope: :provider }
end
