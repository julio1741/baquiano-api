FactoryBot.define do
  factory :refund do
    order
    payment_intent { association :payment_intent, order: order, customer: order.customer }
    requested_by_user { association :user }
    status { "requested" }
    reason_code { "customer_request" }
    amount { 500 }
    currency { "VES" }
    requested_at { Time.current }
    sequence(:idempotency_key) { |n| "refund-key-#{n}" }
  end
end
