FactoryBot.define do
  factory :pos_payment_record do
    payment_intent
    confirmed_by_user { association :user }
    confirmed_at { Time.current }
    amount { 1_000 }
    currency { "VES" }
  end
end
