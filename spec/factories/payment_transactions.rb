FactoryBot.define do
  factory :payment_transaction do
    payment_intent
    transaction_type { "payment" }
    status { "succeeded" }
    amount { 1_000 }
    currency { "VES" }
    occurred_at { Time.current }
    sequence(:idempotency_key) { |n| "payment-txn-key-#{n}" }
  end
end
