FactoryBot.define do
  factory :idempotency_record do
    actor_type { "User" }
    actor_id { SecureRandom.uuid }
    operation { "test_operation" }
    sequence(:key) { |n| "idempotency-key-#{n}" }
    request_digest { "digest" }
    expires_at { 24.hours.from_now }
  end
end
