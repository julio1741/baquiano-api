module Api
  module V1
    module Customer
      class CartItemsController < Api::V1::BaseController
        include Authenticatable

        def create
          cart = Cart.find(params[:cart_id])
          authorize cart, :update?

          item = Carts::AddItem.call(
            cart: cart,
            product: Product.find(item_params[:product_id]),
            product_variant: item_params[:product_variant_id].presence && ProductVariant.find(item_params[:product_variant_id]),
            quantity: item_params[:quantity],
            modifier_ids: Array(params[:modifier_ids]),
            notes: item_params[:notes]
          )
          render json: item_body(item), status: :created
        end

        def update
          item = CartItem.find(params[:id])
          authorize item.cart, :update?
          Carts::UpdateItemQuantity.call(cart_item: item, quantity: item_params[:quantity])
          render json: item_body(item)
        end

        def destroy
          item = CartItem.find(params[:id])
          authorize item.cart, :update?
          Carts::RemoveItem.call(cart_item: item)
          head :no_content
        end

        private

        def item_params
          params.permit(:product_id, :product_variant_id, :quantity, :notes)
        end

        def item_body(item)
          {
            id: item.id,
            product_id: item.product_id,
            product_variant_id: item.product_variant_id,
            quantity: item.quantity,
            unit_price_amount_snapshot: item.unit_price_amount_snapshot,
            line_total: item.line_total
          }
        end
      end
    end
  end
end
