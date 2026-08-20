require "rails_helper"

RSpec.describe Payments::ExpirePaymentIntentsJob, type: :job do
  it "expires a stale mobile payment intent and cancels its still-payment_pending order" do
    order = create(:order, current_status: "payment_pending", payment_status: "pending", payment_method: "mobile_payment")
    pi = Payments::CreatePaymentIntent.call(order: order)
    pi.update_columns(expires_at: 1.minute.ago)

    described_class.perform_now

    expect(pi.reload.status).to eq("expired")
    expect(order.reload.current_status).to eq("cancelled")
  end

  it "leaves a still-valid intent untouched" do
    order = create(:order, current_status: "payment_pending", payment_status: "pending", payment_method: "mobile_payment")
    pi = Payments::CreatePaymentIntent.call(order: order)

    described_class.perform_now

    expect(pi.reload.status).to eq("pending_customer_action")
  end

  it "does not re-cancel an order that already moved on" do
    order = create(:order, current_status: "payment_pending", payment_status: "pending", payment_method: "mobile_payment")
    pi = Payments::CreatePaymentIntent.call(order: order)
    pi.update_columns(expires_at: 1.minute.ago, status: "pending_review")

    described_class.perform_now

    expect(pi.reload.status).to eq("pending_review")
    expect(order.reload.current_status).to eq("payment_pending")
  end
end
