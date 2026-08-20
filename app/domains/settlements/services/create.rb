module Settlements
  # Computed directly from Orders/Deliveries for the period, not from the
  # ledger's running balances — simpler to audit ("this settlement covers
  # exactly these N orders") and doesn't depend on the ledger having been
  # posted correctly. adjustment_amount always starts at 0; manual
  # adjustments are a separate, explicit step (out of scope here — see
  # docs/architecture/decisions.md).
  class Create
    def self.call(...) = new(...).call

    def initialize(beneficiary:, period_start:, period_end:, currency:, idempotency_key:)
      @beneficiary = beneficiary
      @period_start = period_start
      @period_end = period_end
      @currency = currency
      @idempotency_key = idempotency_key
    end

    def call
      existing = Settlement.find_by(idempotency_key: @idempotency_key)
      return existing if existing

      gross, commission = compute_amounts

      Settlement.create!(
        beneficiary: @beneficiary, period_start: @period_start, period_end: @period_end, currency: @currency,
        gross_amount: gross, commission_amount: commission, adjustment_amount: 0, net_amount: gross - commission,
        idempotency_key: @idempotency_key
      )
    end

    private

    def compute_amounts
      case @beneficiary
      when ::Merchant then merchant_amounts
      when ::Courier then courier_amounts
      else raise ValidationError.new("unsupported settlement beneficiary", code: "unsupported_beneficiary")
      end
    end

    def merchant_amounts
      orders = Order.where(merchant_id: @beneficiary.id, currency: @currency)
        .where(current_status: %w[delivered refunded partially_refunded closed])
        .where(delivered_at: @period_start.beginning_of_day..@period_end.end_of_day)

      gross = orders.sum { |order| order.subtotal_amount + order.tax_amount - order.discount_amount }
      commission = orders.sum do |order|
        (order.subtotal_amount + order.tax_amount - order.discount_amount) *
          @beneficiary.commission_rate_basis_points.to_i / 10_000
      end
      [ gross, commission ]
    end

    def courier_amounts
      orders = Order.joins(:delivery).where(deliveries: { courier_id: @beneficiary.id, status: "delivered" },
                                             currency: @currency)
        .where(delivered_at: @period_start.beginning_of_day..@period_end.end_of_day)

      [ orders.sum(:delivery_fee_amount), 0 ]
    end
  end
end
