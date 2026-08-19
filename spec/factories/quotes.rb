FactoryBot.define do
  factory :quote do
    cart
    customer
    branch
    address
    currency { "VES" }
    subtotal_amount { 1_000 }
    total_amount { 1_000 }
    expires_at { 10.minutes.from_now }
    sequence(:idempotency_key) { |n| "quote-key-#{n}" }
  end
end
