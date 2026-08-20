module Payments
  # Section 8: "Expiración de cotizaciones" has a sibling here for
  # payments — a mobile_payment order whose customer never submits a
  # reference within the window shouldn't sit in payment_pending forever.
  class ExpirePaymentIntentsJob < ApplicationJob
    queue_as :maintenance

    def perform
      PaymentIntent.where(status: "pending_customer_action").where(expires_at: ...Time.current).find_each do |pi|
        Payments::TransitionPaymentIntent.call(payment_intent: pi, to_status: "expired")

        order = pi.order
        next unless order.current_status_payment_pending?

        Orders::TransitionOrder.call(order: order, to_status: "cancelled", actor_type: "system")
      rescue ConflictError
        next
      end
    end
  end
end
