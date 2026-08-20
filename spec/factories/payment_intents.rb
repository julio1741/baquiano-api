FactoryBot.define do
  factory :payment_intent do
    order
    customer { order.customer }
    provider { "manual" }
    payment_method { "mobile_payment" }
    status { "created" }
    amount { 1_000 }
    currency { "VES" }
    sequence(:idempotency_key) { |n| "payment-intent-key-#{n}" }
  end
end
