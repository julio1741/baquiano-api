# Immutable snapshot — never updated after creation, even if the underlying
# product's name/price changes later (section 4.9: "No actualizar nombres o
# precios históricos cuando cambie el catálogo").
class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :source_product, class_name: "Product", optional: true
  belongs_to :source_variant, class_name: "ProductVariant", optional: true
  has_many :order_item_modifiers, dependent: :restrict_with_error

  validates :sku_snapshot, :name_snapshot, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price_amount, :line_total_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  def readonly?
    persisted?
  end
end
