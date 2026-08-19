FactoryBot.define do
  factory :product do
    catalog
    category { association :category, catalog: catalog }
    sequence(:sku) { |n| "SKU-#{n}" }
    sequence(:name) { |n| "Producto #{n}" }
    product_type { "simple" }
    base_price_amount { 1_000 }
    currency { "VES" }
  end
end
