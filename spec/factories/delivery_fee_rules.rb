FactoryBot.define do
  factory :delivery_fee_rule do
    city
    sequence(:name) { |n| "Tarifa #{n}" }
    calculation_type { "fixed" }
    base_amount { 150 }
    currency { "VES" }
    valid_from { Date.current }
  end
end
