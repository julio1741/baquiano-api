FactoryBot.define do
  factory :notification do
    user
    channel { "push" }
    template_code { "order_status_changed" }
    scheduled_at { Time.current }
    sequence(:idempotency_key) { |n| "notification-key-#{n}" }
  end
end
