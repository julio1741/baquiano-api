FactoryBot.define do
  factory :user_identity do
    user
    provider { "google" }
    sequence(:provider_subject) { |n| "subject-#{n}" }
  end
end
