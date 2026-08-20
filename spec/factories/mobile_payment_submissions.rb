FactoryBot.define do
  factory :mobile_payment_submission do
    payment_intent
    sequence(:reference) { |n| "REF#{n}" }
    payer_document_masked { "V-****5678" }
    payer_phone_masked { "0414-***4567" }
    amount { 1_000 }
    currency { "VES" }
    paid_at { Time.current }
  end
end
