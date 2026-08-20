module Api
  module V1
    module Customer
      class OrdersController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Customer::CustomerScoped

        def index
          authorize current_customer.orders.new
          render json: current_customer.orders.order(placed_at: :desc).map { |order| order_body(order) }
        end

        def show
          order = current_customer.orders.find(params[:id])
          authorize order
          render json: order_body(order)
        end

        def create
          quote = Quote.find(params[:quote_id])
          authorize quote, :show?

          order = Orders::PlaceOrder.call(
            quote: quote,
            payment_method: order_params[:payment_method],
            customer_notes: order_params[:customer_notes],
            idempotency_key: order_params.fetch(:idempotency_key)
          )
          render json: order_body(order), status: :created
        end

        def request_cancellation
          order = current_customer.orders.find(params[:id])
          authorize order, :cancel?

          Orders::RequestCancellation.call(
            order: order, customer_user: current_user, reason_code: cancellation_params[:reason_code],
            notes: cancellation_params[:notes], idempotency_key: cancellation_params[:idempotency_key]
          )
          render json: order_body(order.reload)
        end

        private

        def order_params
          params.permit(:payment_method, :customer_notes, :idempotency_key)
        end

        def cancellation_params
          params.permit(:reason_code, :notes, :idempotency_key)
        end

        def order_body(order)
          {
            id: order.id,
            public_number: order.public_number,
            current_status: order.current_status,
            payment_status: order.payment_status,
            currency: order.currency,
            subtotal_amount: order.subtotal_amount,
            tax_amount: order.tax_amount,
            delivery_fee_amount: order.delivery_fee_amount,
            total_amount: order.total_amount,
            placed_at: order.placed_at,
            items: order.order_items.map { |item| item_body(item) }
          }
        end

        def item_body(item)
          {
            id: item.id,
            name_snapshot: item.name_snapshot,
            quantity: item.quantity,
            unit_price_amount: item.unit_price_amount,
            line_total_amount: item.line_total_amount
          }
        end
      end
    end
  end
end
