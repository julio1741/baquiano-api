module Cash
  # Section 10, scenario 18: "Efectivo supera límite". A courier who isn't
  # cash-enabled, is blocked, or would exceed their exposure_limit cannot
  # collect a cash payment — checked before the payment_intent ever
  # captures, not after.
  class CollectCashPayment
    def self.call(...) = new(...).call

    def initialize(payment_intent:, courier:)
      @payment_intent = payment_intent
      @courier = courier
    end

    def call
      unless @payment_intent.status_created? && @payment_intent.payment_method_cash?
        raise ConflictError.new("this payment is not awaiting a cash collection", code: "unexpected_payment_status")
      end

      balance = find_or_create_balance

      unless @courier.cash_enabled
        raise ForbiddenError.new("this courier is not enabled to collect cash", code: "cash_not_enabled")
      end
      raise ForbiddenError.new("this courier is blocked from cash orders", code: "cash_blocked") if balance.blocked_for_cash_orders

      projected = balance.amount_held + @payment_intent.amount
      if projected > balance.exposure_limit
        raise ConflictError.new("this would exceed the courier's cash exposure limit", code: "cash_exposure_exceeded")
      end

      ActiveRecord::Base.transaction do
        balance.update!(amount_held: projected, calculated_at: Time.current)
        Payments::TransitionPaymentIntent.call(payment_intent: @payment_intent, to_status: "captured")
      end

      balance
    end

    private

    def find_or_create_balance
      CashBalance.find_or_create_by!(courier: @courier, currency: @payment_intent.currency) do |balance|
        balance.exposure_limit = @courier.maximum_cash_exposure || 0
        balance.calculated_at = Time.current
      end
    end
  end
end
