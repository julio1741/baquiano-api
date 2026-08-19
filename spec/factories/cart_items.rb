FactoryBot.define do
  factory :cart_item do
    cart
    product { association :product, catalog: association(:catalog, branch: cart.branch) }
    quantity { 1 }
    unit_price_amount_snapshot { 1_000 }
    currency { "VES" }
  end
end
