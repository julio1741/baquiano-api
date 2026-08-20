FactoryBot.define do
  factory :order_item_modifier do
    order_item
    modifier_group_name_snapshot { "Extras" }
    modifier_name_snapshot { "Queso" }
    quantity { 1 }
    unit_price_amount { 200 }
    total_amount { 200 }
    currency { "VES" }
  end
end
