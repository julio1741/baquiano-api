module Payments
  # Called right after an order is placed (Orders::PlaceOrder), regardless
  # of payment_method — every order gets exactly one PaymentIntent so the
  # accounting/ledger side always has something to point at. Only
  # mobile_payment needs to move past "created" immediately (it's the only
  # method that blocks the order from proceeding); cash/pos_on_delivery
  # stay in "created" until the courier actually collects payment at
  # delivery time (Payments::RecordPosPayment or a cash handover).
  class CreatePaymentIntent
    MOBILE_PAYMENT_WINDOW = 30.minutes

    def self.call(...) = new(...).call

    def initialize(order:)
      @order = order
    end

    def call
      existing = PaymentIntent.find_by(order: @order)
      return existing if existing

      payment_intent = PaymentIntent.create!(
        order: @order, customer: @order.customer, payment_method: @order.payment_method,
        amount: @order.total_amount, currency: @order.currency, idempotency_key: @order.idempotency_key
      )

      if @order.payment_method_mobile_payment?
        payment_intent.update!(expires_at: MOBILE_PAYMENT_WINDOW.from_now)
        Payments::TransitionPaymentIntent.call(payment_intent: payment_intent, to_status: "pending_customer_action")
      end

      payment_intent
    end
  end
end
