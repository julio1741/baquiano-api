FactoryBot.define do
  factory :product_variant do
    product
    sequence(:sku) { |n| "SKU-VAR-#{n}" }
    sequence(:name) { |n| "Variante #{n}" }
    price_amount { 1_000 }
    currency { "VES" }
  end
end
