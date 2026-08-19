FactoryBot.define do
  factory :session do
    user
    device
    sequence(:refresh_token_digest) { |n| "digest-#{n}" }
    expires_at { 30.days.from_now }
  end
end
