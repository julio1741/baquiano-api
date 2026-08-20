FactoryBot.define do
  factory :ledger_transaction do
    transaction_type { "order_settlement" }
    reference_type { "Order" }
    reference_id { SecureRandom.uuid }
    sequence(:idempotency_key) { |n| "ledger-txn-key-#{n}" }
    effective_at { Time.current }
    posted_at { Time.current }
  end
end
