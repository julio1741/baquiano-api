module Carts
  class UpdateItemQuantity
    def self.call(cart_item:, quantity:)
      cart_item.update!(quantity: quantity)
      cart_item
    end
  end
end
