module Carts
  # Snapshots the current price at add-time — cart_items/cart_item_modifiers
  # never look up live catalog prices later (section 4.7 of the spec).
  class AddItem
    def self.call(...) = new(...).call

    def initialize(cart:, product:, quantity:, product_variant: nil, modifier_ids: [], notes: nil)
      @cart = cart
      @product = product
      @product_variant = product_variant
      @quantity = quantity
      @modifier_ids = modifier_ids
      @notes = notes
    end

    def call
      ActiveRecord::Base.transaction do
        item = CartItem.create!(
          cart: @cart,
          product: @product,
          product_variant: @product_variant,
          quantity: @quantity,
          unit_price_amount_snapshot: unit_price,
          currency: currency,
          notes: @notes
        )

        Modifier.where(id: @modifier_ids).find_each do |modifier|
          CartItemModifier.create!(
            cart_item: item,
            modifier: modifier,
            additional_price_amount_snapshot: modifier.additional_price_amount,
            currency: modifier.currency
          )
        end

        item
      end
    end

    private

    def unit_price
      @product_variant ? @product_variant.price_amount : @product.base_price_amount
    end

    def currency
      @product_variant ? @product_variant.currency : @product.currency
    end
  end
end
