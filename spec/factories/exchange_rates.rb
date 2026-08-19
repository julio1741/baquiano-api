FactoryBot.define do
  factory :exchange_rate do
    base_currency { "USD" }
    quote_currency { "VES" }
    rate_numerator { 36_500_000 }
    rate_denominator { 1_000_000 }
    source { "BCV" }
    rate_type { "official" }
    effective_at { Time.current }
    created_by_user { association :user }
  end
end
