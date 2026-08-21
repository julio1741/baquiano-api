FactoryBot.define do
  factory :feature_flag do
    sequence(:key) { |n| "test_flag_#{n}" }
    created_by_user { association :user }
    updated_by_user { created_by_user }
  end
end
