FactoryBot.define do
  factory :outbox_event do
    aggregate_type { "Order" }
    aggregate_id { SecureRandom.uuid }
    event_type { "OrderPlaced" }
    available_at { Time.current }
  end
end
