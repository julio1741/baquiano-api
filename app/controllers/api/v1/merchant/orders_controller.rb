module Api
  module V1
    module Merchant
      class OrdersController < Api::V1::BaseController
        include Authenticatable

        ACTIVE_STATUSES = %w[merchant_pending merchant_accepted preparing ready_for_pickup].freeze

        def index
          branch = Branch.find(params[:branch_id])
          authorize Order.new(branch: branch, organization: branch.organization, merchant: branch.merchant), :index?

          orders = branch.orders.where(current_status: ACTIVE_STATUSES).order(placed_at: :asc)
          render json: orders.map { |order| order_body(order) }
        end

        def show
          order = Order.find(params[:id])
          authorize order, :show?
          render json: order_body(order)
        end

        def accept
          render json: order_body(transition(to_status: "merchant_accepted").reload)
        end

        def reject
          order = transition(to_status: "merchant_rejected", reason_code: params[:reason_code], notes: params[:notes])
          render json: order_body(order.reload)
        end

        def start_preparing
          render json: order_body(transition(to_status: "preparing").reload)
        end

        def mark_ready
          order = transition(to_status: "ready_for_pickup")
          Deliveries::CreateForOrder.call(order: order)
          render json: order_body(order.reload)
        end

        private

        def transition(to_status:, reason_code: nil, notes: nil)
          order = Order.find(params[:id])
          authorize order, :update_status?

          Orders::TransitionOrder.call(
            order: order, to_status: to_status, actor_type: "merchant_staff", actor_user: current_user,
            reason_code: reason_code, notes: notes, idempotency_key: params[:idempotency_key]
          )
          order
        end

        def order_body(order)
          {
            id: order.id,
            public_number: order.public_number,
            current_status: order.current_status,
            payment_status: order.payment_status,
            currency: order.currency,
            total_amount: order.total_amount,
            customer_notes: order.customer_notes,
            placed_at: order.placed_at,
            items: order.order_items.map { |item| item_body(item) }
          }
        end

        def item_body(item)
          {
            id: item.id,
            name_snapshot: item.name_snapshot,
            variant_name_snapshot: item.variant_name_snapshot,
            quantity: item.quantity,
            notes: item.notes
          }
        end
      end
    end
  end
end
