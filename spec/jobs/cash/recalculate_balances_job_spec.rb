require "rails_helper"

RSpec.describe Cash::RecalculateBalancesJob, type: :job do
  it "recomputes amount_held from captured cash payments minus confirmed handovers" do
    courier = create(:courier, cash_enabled: true, maximum_cash_exposure: 5_000)
    delivery = create(:delivery, courier: courier)
    delivery.order.update!(payment_method: "cash", total_amount: 1_000)
    pi = Payments::CreatePaymentIntent.call(order: delivery.order)
    Cash::CollectCashPayment.call(payment_intent: pi, courier: courier)

    balance = CashBalance.find_by(courier: courier)
    # Simulate drift: something nudged the stored balance away from ground truth.
    balance.update_columns(amount_held: 9_999)

    described_class.perform_now

    expect(balance.reload.amount_held).to eq(1_000)
  end

  it "subtracts confirmed handovers from the recomputed total" do
    courier = create(:courier, cash_enabled: true, maximum_cash_exposure: 5_000)
    delivery = create(:delivery, courier: courier)
    delivery.order.update!(payment_method: "cash", total_amount: 1_000)
    pi = Payments::CreatePaymentIntent.call(order: delivery.order)
    Cash::CollectCashPayment.call(payment_intent: pi, courier: courier)

    supervisor = create(:user)
    handover = Cash::InitiateHandover.call(courier: courier, received_by: supervisor, amount: 400,
                                            idempotency_key: "recalc-handover-1")
    Cash::ConfirmHandover.call(handover: handover)

    balance = CashBalance.find_by(courier: courier)
    balance.update_columns(amount_held: 0)

    described_class.perform_now

    expect(balance.reload.amount_held).to eq(600)
  end
end
