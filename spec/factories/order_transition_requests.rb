FactoryBot.define do
  factory :order_transition_request do
    order
    requested_transition { "merchant_accepted" }
    requested_by_user { association :user }
    sequence(:idempotency_key) { |n| "transition-key-#{n}" }
  end
end
