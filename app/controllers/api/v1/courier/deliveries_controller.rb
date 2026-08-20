module Api
  module V1
    module Courier
      class DeliveriesController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Courier::CourierScoped

        def index
          render json: current_courier.deliveries.order(created_at: :desc).map { |delivery| delivery_body(delivery) }
        end

        def show
          delivery = current_courier.deliveries.find(params[:id])
          render json: delivery_body(delivery)
        end

        def arrive_at_merchant
          render json: delivery_body(transition(to_status: "at_merchant"))
        end

        def confirm_pickup
          delivery = current_courier.deliveries.find(params[:id])
          authorize delivery, :update_status?
          Deliveries::ConfirmPickup.call(delivery: delivery, courier: current_courier)
          render json: delivery_body(delivery.reload)
        end

        def arrive_at_customer
          render json: delivery_body(transition(to_status: "at_customer"))
        end

        def confirm_delivery
          render json: delivery_body(transition(to_status: "delivered", pin: params[:pin]))
        end

        def fail_delivery
          render json: delivery_body(transition(to_status: "failed", failure_reason: params[:failure_reason]))
        end

        def collect_cash_payment
          delivery = current_courier.deliveries.find(params[:id])
          payment_intent = delivery.order.payment_intent
          Cash::CollectCashPayment.call(payment_intent: payment_intent, courier: current_courier)
          render json: { payment_intent_status: payment_intent.reload.status }
        end

        def record_pos_payment
          delivery = current_courier.deliveries.find(params[:id])
          payment_intent = delivery.order.payment_intent
          Payments::RecordPosPayment.call(
            payment_intent: payment_intent, confirmed_by: current_user, terminal_owner: current_courier,
            receipt_reference: params[:receipt_reference]
          )
          render json: { payment_intent_status: payment_intent.reload.status }
        end

        private

        def transition(to_status:, pin: nil, failure_reason: nil)
          delivery = current_courier.deliveries.find(params[:id])
          authorize delivery, :update_status?
          Deliveries::TransitionDelivery.call(
            delivery: delivery, to_status: to_status, actor_type: "courier", actor_courier: current_courier,
            pin: pin, failure_reason: failure_reason
          )
          delivery.reload
        end

        def delivery_body(delivery)
          {
            id: delivery.id, order_id: delivery.order_id, status: delivery.status,
            pickup_location: point_body(delivery.pickup_location), dropoff_location: point_body(delivery.dropoff_location),
            assigned_at: delivery.assigned_at, accepted_at: delivery.accepted_at,
            arrived_at_merchant_at: delivery.arrived_at_merchant_at, picked_up_at: delivery.picked_up_at,
            arrived_at_customer_at: delivery.arrived_at_customer_at, delivered_at: delivery.delivered_at,
            failed_at: delivery.failed_at, failure_reason: delivery.failure_reason
          }
        end

        def point_body(point)
          return nil unless point

          { latitude: point.y, longitude: point.x }
        end
      end
    end
  end
end
