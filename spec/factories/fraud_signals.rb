FactoryBot.define do
  factory :fraud_signal do
    subject factory: :customer
    signal_type { "duplicate_mobile_payment_reference" }
    score { 75.0 }
    severity { "high" }
    detected_at { Time.current }
  end
end
