module Payments
  # Same shape as Orders::TransitionOrder/Deliveries::TransitionDelivery:
  # explicit transition table, lock!, idempotent no-op on replay, direct
  # writes rejected at the model level.
  #
  # captured is the one transition that reaches back into Orders — it's
  # what actually lets a payment_pending order move forward, since nothing
  # else in the system does that (see docs/architecture/decisions.md for
  # why Increment 4 could only get the order this far). Refund-driven
  # order transitions are handled by the Payments refund services
  # themselves, not here — a refund's own approve/complete flow already
  # carries its own order-status implications.
  class TransitionPaymentIntent
    TRANSITIONS = {
      %w[created pending_customer_action] => { actor: :system, event_type: "PaymentIntentStatusChanged" },
      %w[pending_customer_action pending_review] => { actor: :system, event_type: "PaymentSubmitted" },
      %w[pending_review captured] => {
        actor: :system, timestamp_column: :captured_at, event_type: "PaymentConfirmed"
      },
      %w[pending_review failed] => {
        actor: :system, timestamp_column: :failed_at, requires_reason: true, event_type: "PaymentRejected"
      },
      %w[created captured] => { actor: :system, timestamp_column: :captured_at, event_type: "PaymentConfirmed" },
      %w[created cancelled] => { actor: :system, event_type: "PaymentIntentStatusChanged" },
      %w[pending_customer_action cancelled] => { actor: :system, event_type: "PaymentIntentStatusChanged" },
      %w[pending_customer_action expired] => { actor: :system, event_type: "PaymentIntentStatusChanged" },
      %w[captured partially_refunded] => { actor: :system, event_type: "RefundCompleted" },
      %w[captured refunded] => { actor: :system, event_type: "RefundCompleted" },
      %w[partially_refunded refunded] => { actor: :system, event_type: "RefundCompleted" }
    }.freeze

    def self.call(...) = new(...).call

    def initialize(payment_intent:, to_status:, actor_type: "system", failure_code: nil, failure_message: nil)
      @payment_intent = payment_intent
      @to_status = to_status.to_s
      @actor_type = actor_type.to_s
      @failure_code = failure_code
      @failure_message = failure_message
    end

    def call
      ActiveRecord::Base.transaction do
        @payment_intent.lock!
        return @payment_intent if @payment_intent.status == @to_status

        rule = TRANSITIONS[[ @payment_intent.status, @to_status ]]
        unless rule
          raise ConflictError.new("cannot transition from #{@payment_intent.status} to #{@to_status}",
                                   code: "invalid_transition")
        end

        if rule[:requires_reason] && @failure_message.blank?
          raise ValidationError.new("failure_message is required for this transition", code: "failure_reason_required")
        end

        from_status = @payment_intent.status
        apply_status!(rule)
        Events::Publish.call(
          aggregate: @payment_intent, event_type: rule[:event_type],
          payload: { payment_intent_id: @payment_intent.id, order_id: @payment_intent.order_id,
                     from_status: from_status, to_status: @to_status }
        )
        sync_order! if @to_status == "captured"
        @payment_intent
      end
    end

    private

    def apply_status!(rule)
      @payment_intent.status_change_authorized = true
      attrs = { status: @to_status }
      attrs[rule[:timestamp_column]] = Time.current if rule[:timestamp_column]
      if @to_status == "failed"
        attrs[:failure_code] = @failure_code if @failure_code.present?
        attrs[:failure_message] = @failure_message
      end
      @payment_intent.update!(attrs)
    end

    def sync_order!
      order = @payment_intent.order
      order.update!(payment_status: "confirmed")
      Ledger::RecordOrderSettlementEntries.call(order: order)

      return unless order.current_status_payment_pending?

      Orders::TransitionOrder.call(order: order, to_status: "placed", actor_type: "system")
      Orders::TransitionOrder.call(order: order, to_status: "merchant_pending", actor_type: "system")
    end
  end
end
