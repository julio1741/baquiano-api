FactoryBot.define do
  factory :cart_item_modifier do
    cart_item
    modifier
    quantity { 1 }
    additional_price_amount_snapshot { 200 }
    currency { "VES" }
  end
end
