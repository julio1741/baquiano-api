FactoryBot.define do
  factory :permission do
    resource { "orders" }
    sequence(:action) { |n| "action_#{n}" }
  end
end
