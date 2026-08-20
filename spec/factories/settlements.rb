FactoryBot.define do
  factory :settlement do
    beneficiary factory: :merchant
    period_start { 7.days.ago.to_date }
    period_end { Date.current }
    currency { "VES" }
    gross_amount { 10_000 }
    commission_amount { 1_000 }
    adjustment_amount { 0 }
    net_amount { 9_000 }
    sequence(:idempotency_key) { |n| "settlement-key-#{n}" }
  end
end
