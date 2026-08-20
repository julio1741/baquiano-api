module Payments
  class RequestRefund
    # Orders can only reach refund_pending from these — a rejected order
    # under mobile_payment may already have a captured payment (it's
    # collected upfront, before the merchant ever sees the order), so it
    # needs the same refund path as a delivered or admin-cancelled one.
    TRANSITIONABLE_ORDER_STATUSES = %w[delivered merchant_rejected cancelled].freeze

    def self.call(...) = new(...).call

    def initialize(order:, requested_by:, reason_code:, amount:, idempotency_key:, reason_notes: nil)
      @order = order
      @requested_by = requested_by
      @reason_code = reason_code
      @amount = amount
      @idempotency_key = idempotency_key
      @reason_notes = reason_notes
    end

    def call
      existing = Refund.find_by(order: @order, idempotency_key: @idempotency_key)
      return existing if existing

      payment_intent = @order.payment_intent
      unless payment_intent && (payment_intent.status_captured? || payment_intent.status_partially_refunded?)
        raise ConflictError.new("this order has no captured payment to refund", code: "no_capturable_payment")
      end

      remaining = payment_intent.amount - payment_intent.refunded_amount
      if @amount > remaining
        raise ValidationError.new("refund amount exceeds the remaining refundable amount",
                                   code: "refund_amount_too_high")
      end

      refund = Refund.create!(
        order: @order, payment_intent: payment_intent, requested_by_user: @requested_by, status: "requested",
        reason_code: @reason_code, reason_notes: @reason_notes, amount: @amount, currency: payment_intent.currency,
        idempotency_key: @idempotency_key, requested_at: Time.current
      )

      if TRANSITIONABLE_ORDER_STATUSES.include?(@order.current_status)
        Orders::TransitionOrder.call(order: @order, to_status: "refund_pending", actor_type: "system")
      end

      refund
    end
  end
end
