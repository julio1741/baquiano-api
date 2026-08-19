FactoryBot.define do
  factory :city do
    sequence(:name) { |n| "Barinas #{n}" }
    state_name { "Barinas" }
    country_code { "VE" }
    timezone { "America/Caracas" }
  end
end
