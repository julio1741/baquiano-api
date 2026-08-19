FactoryBot.define do
  factory :cart do
    customer
    branch
    currency { "VES" }
    expires_at { 2.hours.from_now }
  end
end
