FactoryBot.define do
  factory :support_case do
    opened_by_user { association :user }
    category { "order_issue" }
    subject { "No llegó mi pedido" }
    description { "El pedido no llegó a la hora estimada." }
    opened_at { Time.current }
    sequence(:public_number) { |n| "SC-TEST-#{n}" }
  end
end
