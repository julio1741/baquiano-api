module Carts
  class RemoveItem
    def self.call(cart_item:)
      cart_item.destroy!
    end
  end
end
