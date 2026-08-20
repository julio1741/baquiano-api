module Orders
  # Section 8 of the spec: "Timeout de aceptación del comercio". If a
  # merchant hasn't accepted (or rejected) an order within TIMEOUT, cancel
  # it automatically so the customer isn't left waiting indefinitely.
  # Idempotent and safe to run concurrently/repeatedly: if an order was
  # already moved on by the time this runs (accepted, rejected, or
  # cancelled by the customer), TransitionOrder's own invalid_transition
  # check rejects the stale attempt and this job just skips it.
  class AutoCancelUnacceptedOrdersJob < ApplicationJob
    queue_as :maintenance

    TIMEOUT = 15.minutes

    def perform
      Order.where(current_status: "merchant_pending").where(placed_at: ...TIMEOUT.ago).find_each do |order|
        Orders::TransitionOrder.call(
          order: order, to_status: "cancelled", actor_type: "system", reason_code: "merchant_acceptance_timeout"
        )
      rescue ConflictError
        next
      end
    end
  end
end
