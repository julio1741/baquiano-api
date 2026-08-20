FactoryBot.define do
  factory :cash_handover do
    courier
    received_by_user { association :user }
    amount { 1_000 }
    currency { "VES" }
    handed_over_at { Time.current }
    sequence(:idempotency_key) { |n| "handover-key-#{n}" }
  end
end
