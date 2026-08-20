FactoryBot.define do
  factory :reconciliation_batch do
    provider { "manual" }
    payment_method { "mobile_payment" }
    currency { "VES" }
    period_start { 1.day.ago.to_date }
    period_end { Date.current }
    started_by_user { association :user }
    started_at { Time.current }
  end
end
