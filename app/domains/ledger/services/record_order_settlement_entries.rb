module Ledger
  # Posts the minimum set of entries section 4.11 calls out for a captured
  # order payment: cobro cliente, venta comercio, comisión Baquiano,
  # tarifa de entrega. Called once a PaymentIntent reaches "captured"
  # (Payments::TransitionPaymentIntent).
  #
  # The delivery-fee credit always goes to a platform-wide unassigned pool
  # account, never a specific courier — for mobile_payment orders capture
  # happens before the merchant even sees the order, long before any
  # courier is assigned, so there's nothing to attribute it to yet.
  # Reallocating it to the courier who actually delivers is a settlement
  # concern out of scope here — see docs/architecture/decisions.md.
  class RecordOrderSettlementEntries
    def self.call(...) = new(...).call

    def initialize(order:)
      @order = order
    end

    def call
      Ledger::PostTransaction.call(
        transaction_type: "order_settlement",
        reference_type: "Order",
        reference_id: @order.id,
        idempotency_key: "order_settlement:#{@order.id}",
        description: "Settlement for order #{@order.public_number}",
        entries: entries
      )
    end

    private

    def currency = @order.currency

    def entries
      merchant_gross = @order.subtotal_amount + @order.tax_amount - @order.discount_amount
      merchant_commission = merchant_gross * @order.merchant.commission_rate_basis_points.to_i / 10_000
      merchant_net = merchant_gross - merchant_commission
      total_commission = merchant_commission + @order.service_fee_amount

      [
        { account: cash_clearing_account, direction: "debit", amount: @order.total_amount, currency: currency },
        { account: merchant_payable_account, direction: "credit", amount: merchant_net, currency: currency },
        { account: delivery_fee_payable_account, direction: "credit", amount: @order.delivery_fee_amount,
          currency: currency },
        { account: commission_revenue_account, direction: "credit", amount: total_commission, currency: currency }
      ].reject { |entry| entry[:amount].zero? }
    end

    def cash_clearing_account
      find_or_create_account(code: "platform:cash_clearing", type: "asset")
    end

    def merchant_payable_account
      find_or_create_account(code: "merchant:#{@order.merchant_id}:payable", type: "liability",
                              owner: @order.merchant)
    end

    def delivery_fee_payable_account
      find_or_create_account(code: "platform:delivery_fee_payable", type: "liability")
    end

    def commission_revenue_account
      find_or_create_account(code: "platform:commission_revenue", type: "revenue")
    end

    def find_or_create_account(code:, type:, owner: nil)
      LedgerAccount.find_or_create_by!(account_code: code) do |account|
        account.account_type = type
        account.currency = currency
        account.owner = owner
      end
    end
  end
end
