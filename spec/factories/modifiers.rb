FactoryBot.define do
  factory :modifier do
    modifier_group
    sequence(:name) { |n| "Modificador #{n}" }
    additional_price_amount { 0 }
    currency { "VES" }
  end
end
