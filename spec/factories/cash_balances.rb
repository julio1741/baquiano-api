FactoryBot.define do
  factory :cash_balance do
    courier
    currency { "VES" }
    amount_held { 0 }
    exposure_limit { 50_000 }
    calculated_at { Time.current }
  end
end
