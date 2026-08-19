class CartItemModifier < ApplicationRecord
  belongs_to :cart_item
  belongs_to :modifier

  validates :quantity, numericality: { greater_than: 0 }
  validates :additional_price_amount_snapshot, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }

  validate :modifier_belongs_to_product

  private

  def modifier_belongs_to_product
    return if modifier.nil? || cart_item.nil?

    unless modifier.modifier_group.product_id == cart_item.product_id
      errors.add(:modifier, "must belong to the cart item's product")
    end
  end
end
