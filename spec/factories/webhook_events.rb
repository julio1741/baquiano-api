FactoryBot.define do
  factory :webhook_event do
    provider { "generic" }
    sequence(:provider_event_id) { |n| "evt_#{n}" }
    signature_valid { true }
    payload { '{"type":"test"}' }
    received_at { Time.current }
  end
end
