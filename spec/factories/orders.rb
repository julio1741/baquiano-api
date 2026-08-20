FactoryBot.define do
  factory :order do
    customer
    organization { branch.organization }
    merchant { branch.merchant }
    branch
    address { association :address, customer: customer }
    quote { association :quote, cart: association(:cart, customer: customer, branch: branch), customer: customer, branch: branch, address: address }
    current_status { "merchant_pending" }
    payment_status { "not_required" }
    payment_method { "cash" }
    delivery_model { "baquiano" }
    currency { "VES" }
    subtotal_amount { 1_000 }
    total_amount { 1_000 }
    placed_at { Time.current }
    sequence(:public_number) { |n| "BQ-TEST-#{n}" }
    sequence(:idempotency_key) { |n| "order-key-#{n}" }
  end
end
