FactoryBot.define do
  factory :order_status_history do
    order
    to_status { "merchant_pending" }
    actor_type { "system" }
    occurred_at { Time.current }
  end
end
