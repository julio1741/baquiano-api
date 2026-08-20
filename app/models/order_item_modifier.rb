class OrderItemModifier < ApplicationRecord
  belongs_to :order_item
  belongs_to :source_modifier, class_name: "Modifier", optional: true

  validates :modifier_group_name_snapshot, :modifier_name_snapshot, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price_amount, :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  def readonly?
    persisted?
  end
end
