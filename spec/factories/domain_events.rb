FactoryBot.define do
  factory :domain_event do
    aggregate_type { "Order" }
    aggregate_id { SecureRandom.uuid }
    event_type { "OrderPlaced" }
    occurred_at { Time.current }
    correlation_id { SecureRandom.uuid }
  end
end
