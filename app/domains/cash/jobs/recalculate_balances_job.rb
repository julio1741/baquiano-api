module Cash
  # Section 8: "Actualización de balances de efectivo". CashBalance.amount_held
  # is updated incrementally as cash is collected/handed over
  # (Cash::CollectCashPayment / Cash::ConfirmHandover) — this periodic job
  # recomputes it from ground truth (captured cash payment_intents linked
  # to the courier via their delivery, minus confirmed handovers) so any
  # drift from a missed update gets corrected rather than compounding.
  class RecalculateBalancesJob < ApplicationJob
    queue_as :maintenance

    def perform
      CashBalance.find_each do |balance|
        collected = collected_amount(balance)
        handed_over = handed_over_amount(balance)
        balance.update!(amount_held: [ collected - handed_over, 0 ].max, calculated_at: Time.current)
      end
    end

    private

    def collected_amount(balance)
      PaymentIntent.joins(order: :delivery)
        .where(payment_method: "cash", status: "captured", currency: balance.currency,
               deliveries: { courier_id: balance.courier_id })
        .sum(:amount)
    end

    def handed_over_amount(balance)
      CashHandover.where(courier_id: balance.courier_id, currency: balance.currency, status: "confirmed").sum(:amount)
    end
  end
end
