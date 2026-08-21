FactoryBot.define do
  factory :notification_preference do
    user
    notification_type { "order_status_changed" }
  end
end
