FactoryBot.define do
  factory :user do
    sequence(:phone_number) { |n| format("41%08d", n) }
    phone_country_code { "58" }
    first_name { "Julio" }
    last_name { "Baptista" }

    trait :active do
      status { :active }
      phone_verified_at { Time.current }
    end
  end
end
