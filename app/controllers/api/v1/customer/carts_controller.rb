module Api
  module V1
    module Customer
      class CartsController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Customer::CustomerScoped

        def create
          branch = Branch.find(params[:branch_id])
          cart = Carts::GetOrCreateActiveCart.call(customer: current_customer, branch: branch)
          authorize cart
          render json: cart_body(cart)
        end

        def show
          cart = Cart.find(params[:id])
          authorize cart
          render json: cart_body(cart)
        end

        private

        def cart_body(cart)
          {
            id: cart.id,
            branch_id: cart.branch_id,
            status: cart.status,
            currency: cart.currency,
            expires_at: cart.expires_at,
            items: cart.cart_items.map { |item| item_body(item) }
          }
        end

        def item_body(item)
          {
            id: item.id,
            product_id: item.product_id,
            product_variant_id: item.product_variant_id,
            quantity: item.quantity,
            unit_price_amount_snapshot: item.unit_price_amount_snapshot,
            line_total: item.line_total,
            modifiers: item.cart_item_modifiers.map do |modifier|
              { modifier_id: modifier.modifier_id, quantity: modifier.quantity,
                additional_price_amount_snapshot: modifier.additional_price_amount_snapshot }
            end
          }
        end
      end
    end
  end
end
