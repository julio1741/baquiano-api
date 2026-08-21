module Webhooks
  # Idempotent on (provider, provider_event_id) — section 10, scenario 6:
  # "Webhook repetido" must never process twice or even look different to
  # the caller on replay, so a repeat just returns the original record.
  #
  # No real provider is wired up (section 16: "no inventar integraciones
  # bancarias") — this only receives, verifies, and stores; there is no
  # per-provider payload processor yet. See docs/architecture/decisions.md.
  class Receive
    def self.call(...) = new(...).call

    def initialize(provider:, provider_event_id:, raw_body:, signature:, event_type: nil)
      @provider = provider
      @provider_event_id = provider_event_id
      @raw_body = raw_body
      @signature = signature
      @event_type = event_type
    end

    def call
      existing = WebhookEvent.find_by(provider: @provider, provider_event_id: @provider_event_id)
      return existing if existing

      WebhookEvent.create!(
        provider: @provider, provider_event_id: @provider_event_id, event_type: @event_type,
        signature_valid: valid_signature?, payload: @raw_body, status: "received", received_at: Time.current
      )
    end

    private

    def valid_signature?
      secret = ENV["WEBHOOK_SECRET_#{@provider.to_s.upcase}"]
      return false if secret.blank? || @signature.blank?

      expected = OpenSSL::HMAC.hexdigest("SHA256", secret, @raw_body.to_s)
      ActiveSupport::SecurityUtils.secure_compare(expected, @signature)
    end
  end
end
