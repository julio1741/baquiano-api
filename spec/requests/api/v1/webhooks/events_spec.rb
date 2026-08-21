require "rails_helper"

RSpec.describe "Webhooks receiving", type: :request do
  it "receives, verifies, and stores a webhook event" do
    ENV["WEBHOOK_SECRET_STRIPE"] = "test-secret"
    body = '{"id":"evt_1","type":"payment.succeeded"}'
    signature = OpenSSL::HMAC.hexdigest("SHA256", "test-secret", body)

    post "/api/v1/webhooks/stripe", params: body, headers: { "Content-Type" => "application/json",
                                                              "X-Webhook-Signature" => signature }

    expect(response).to have_http_status(:ok)
    event = WebhookEvent.find_by(provider: "stripe", provider_event_id: "evt_1")
    expect(event).to be_present
    expect(event.signature_valid).to be true
  ensure
    ENV.delete("WEBHOOK_SECRET_STRIPE")
  end

  it "is idempotent on repeated delivery of the same event (scenario: webhook repetido)" do
    body = '{"id":"evt_2","type":"payment.succeeded"}'

    post "/api/v1/webhooks/stripe", params: body, headers: { "Content-Type" => "application/json" }
    first_id = response.parsed_body["id"]

    post "/api/v1/webhooks/stripe", params: body, headers: { "Content-Type" => "application/json" }
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["id"]).to eq(first_id)
    expect(WebhookEvent.where(provider: "stripe", provider_event_id: "evt_2").count).to eq(1)
  end

  it "still stores an event with an invalid or missing signature, but flags it" do
    body = '{"id":"evt_3","type":"payment.succeeded"}'

    post "/api/v1/webhooks/stripe", params: body, headers: { "Content-Type" => "application/json",
                                                              "X-Webhook-Signature" => "bogus" }

    expect(response).to have_http_status(:ok)
    event = WebhookEvent.find_by(provider: "stripe", provider_event_id: "evt_3")
    expect(event.signature_valid).to be false
  end
end
