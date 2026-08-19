FactoryBot.define do
  factory :merchant do
    organization
    sequence(:slug) { |n| "merchant-#{n}" }
    vertical { :restaurant }
  end
end
