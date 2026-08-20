module Api
  module V1
    module Admin
      # Read-only visibility for platform admins/ops. No status-changing
      # actions here on purpose: refunds/disputes are Payments domain
      # territory (Increment 6, still unbuilt), and forcing merchant/courier
      # transitions from the admin panel isn't in this MVP's scope — see
      # docs/architecture/decisions.md.
      class OrdersController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize Order.new, :index?

          orders = Order.all
          orders = orders.where(organization_id: params[:organization_id]) if params[:organization_id].present?
          orders = orders.where(current_status: params[:status]) if params[:status].present?
          orders = orders.order(placed_at: :desc)
          render json: orders.map { |order| order_body(order) }
        end

        def show
          order = Order.find(params[:id])
          authorize order, :show?
          render json: order_body(order).merge(status_history: order.order_status_histories.order(:occurred_at).map { |h| history_body(h) })
        end

        private

        def order_body(order)
          {
            id: order.id,
            public_number: order.public_number,
            organization_id: order.organization_id,
            merchant_id: order.merchant_id,
            branch_id: order.branch_id,
            customer_id: order.customer_id,
            current_status: order.current_status,
            payment_status: order.payment_status,
            fulfillment_type: order.fulfillment_type,
            delivery_model: order.delivery_model,
            currency: order.currency,
            total_amount: order.total_amount,
            cancellation_reason_code: order.cancellation_reason_code,
            placed_at: order.placed_at,
            merchant_accepted_at: order.merchant_accepted_at,
            ready_at: order.ready_at,
            picked_up_at: order.picked_up_at,
            delivered_at: order.delivered_at,
            cancelled_at: order.cancelled_at
          }
        end

        def history_body(history)
          {
            from_status: history.from_status,
            to_status: history.to_status,
            actor_type: history.actor_type,
            actor_user_id: history.actor_user_id,
            reason_code: history.reason_code,
            occurred_at: history.occurred_at
          }
        end
      end
    end
  end
end
