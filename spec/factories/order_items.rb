FactoryBot.define do
  factory :order_item do
    order
    sequence(:sku_snapshot) { |n| "SKU-#{n}" }
    name_snapshot { "Producto" }
    quantity { 1 }
    unit_price_amount { 1_000 }
    line_total_amount { 1_000 }
    currency { "VES" }
  end
end
