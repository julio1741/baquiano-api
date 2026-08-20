module Orders
  # Cancelling before the merchant has accepted (or before payment is even
  # confirmed) is free and immediate. Cancelling after acceptance instead
  # flags the order for merchant/admin review — work may already be
  # underway, so it isn't the customer's call alone.
  class RequestCancellation
    DIRECT_CANCEL_STATUSES = %w[payment_pending merchant_pending].freeze
    REVIEW_REQUIRED_STATUSES = %w[merchant_accepted preparing].freeze

    def self.call(...) = new(...).call

    def initialize(order:, customer_user:, reason_code: nil, notes: nil, idempotency_key: nil)
      @order = order
      @customer_user = customer_user
      @reason_code = reason_code
      @notes = notes
      @idempotency_key = idempotency_key
    end

    def call
      Orders::TransitionOrder.call(
        order: @order, to_status: target_status, actor_type: "customer", actor_user: @customer_user,
        reason_code: @reason_code, notes: @notes, idempotency_key: @idempotency_key
      )
    end

    private

    def target_status
      return "cancelled" if DIRECT_CANCEL_STATUSES.include?(@order.current_status)
      return "cancellation_requested" if REVIEW_REQUIRED_STATUSES.include?(@order.current_status)

      raise ConflictError.new("order can no longer be cancelled", code: "not_cancellable")
    end
  end
end
