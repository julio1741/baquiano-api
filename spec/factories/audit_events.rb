FactoryBot.define do
  factory :audit_event do
    actor_type { "user" }
    action { "test.action" }
    resource_type { "Order" }
    occurred_at { Time.current }
  end
end
