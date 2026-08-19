class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product
  belongs_to :product_variant, optional: true
  has_many :cart_item_modifiers, dependent: :destroy

  validates :quantity, numericality: { greater_than: 0 }
  validates :unit_price_amount_snapshot, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }

  validate :product_belongs_to_cart_branch
  validate :variant_belongs_to_product

  def line_total
    modifiers_total_per_unit = cart_item_modifiers.sum { |m| m.additional_price_amount_snapshot * m.quantity }
    (unit_price_amount_snapshot + modifiers_total_per_unit) * quantity
  end

  private

  def product_belongs_to_cart_branch
    return if product.nil? || cart.nil?

    errors.add(:product, "must belong to the cart's branch catalog") if product.catalog.branch_id != cart.branch_id
  end

  def variant_belongs_to_product
    return if product_variant.nil?

    errors.add(:product_variant, "must belong to the selected product") if product_variant.product_id != product_id
  end
end
