module Payments
  # Approve and execute happen in one step — there's no real payment
  # gateway to wait on (section 16: "no inventar integraciones
  # bancarias"), so "approved" a staff member manually sends the money
  # back outside this system and records it as done here. Rejecting just
  # closes the request out; the order's payment status is untouched.
  class DecideRefund
    def self.call(...) = new(...).call

    def initialize(refund:, decided_by:, approve:, failure_code: nil)
      @refund = refund
      @decided_by = decided_by
      @approve = approve
      @failure_code = failure_code
    end

    def call
      raise ConflictError.new("this refund is not pending a decision", code: "not_requested") unless @refund.requested?

      # Section 10, scenario 22: an admin can't approve their own request —
      # generalized from adjustments to every money-moving approval.
      if @approve && @refund.requested_by_user_id == @decided_by.id
        raise ForbiddenError.new("cannot approve your own refund request", code: "self_approval_forbidden")
      end

      @approve ? approve_and_complete! : reject!
    end

    private

    def approve_and_complete!
      ActiveRecord::Base.transaction do
        @refund.status_change_authorized = true
        @refund.update!(status: "completed", approved_by_user: @decided_by, approved_at: Time.current,
                         completed_at: Time.current)

        payment_intent = @refund.payment_intent
        PaymentTransaction.create!(
          payment_intent: payment_intent, transaction_type: "refund", status: "succeeded", amount: @refund.amount,
          currency: @refund.currency, idempotency_key: @refund.idempotency_key, occurred_at: Time.current
        )
        Ledger::RecordRefundEntries.call(refund: @refund)

        fully_refunded = payment_intent.refunded_amount >= payment_intent.amount
        Payments::TransitionPaymentIntent.call(
          payment_intent: payment_intent, to_status: fully_refunded ? "refunded" : "partially_refunded"
        )

        order = @refund.order
        order.update!(payment_status: "refunded")
        target_order_status = fully_refunded ? "refunded" : "partially_refunded"
        can_transition = order.current_status_refund_pending? || order.current_status_partially_refunded?
        if can_transition && order.current_status != target_order_status
          Orders::TransitionOrder.call(order: order, to_status: target_order_status, actor_type: "system")
        end
      end
      @refund
    end

    def reject!
      @refund.status_change_authorized = true
      @refund.update!(status: "rejected", approved_by_user: @decided_by, failure_code: @failure_code,
                       failed_at: Time.current)
      @refund
    end
  end
end
