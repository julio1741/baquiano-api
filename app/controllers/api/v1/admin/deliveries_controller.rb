module Api
  module V1
    module Admin
      # Read/assign only — the delivery lifecycle itself (accept, arrive,
      # pick up, deliver) is always courier-driven, see
      # Api::V1::Courier::DeliveriesController.
      class DeliveriesController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize Delivery.new, :show?
          deliveries = Delivery.all
          deliveries = deliveries.where(status: params[:status]) if params[:status].present?
          render json: deliveries.map { |delivery| delivery_body(delivery) }
        end

        def show
          delivery = Delivery.find(params[:id])
          authorize delivery, :show?
          render json: delivery_body(delivery)
        end

        def assign
          delivery = Delivery.find(params[:id])
          authorize delivery, :assign?
          courier = ::Courier.find(params[:courier_id])
          Deliveries::TransitionDelivery.call(
            delivery: delivery, to_status: "assigned", actor_type: "system", extra_attrs: { courier_id: courier.id }
          )
          render json: delivery_body(delivery.reload)
        end

        private

        def delivery_body(delivery)
          {
            id: delivery.id, order_id: delivery.order_id, branch_id: delivery.branch_id,
            courier_id: delivery.courier_id, status: delivery.status, assigned_at: delivery.assigned_at,
            accepted_at: delivery.accepted_at, delivered_at: delivery.delivered_at,
            failed_at: delivery.failed_at, failure_reason: delivery.failure_reason
          }
        end
      end
    end
  end
end
