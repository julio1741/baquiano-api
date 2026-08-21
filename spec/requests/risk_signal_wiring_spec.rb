require "rails_helper"

RSpec.describe "Risk/fraud signals wired into payments and location tracking", type: :request do
  it "records a fraud signal synchronously when a mobile payment reference is reused across orders" do
    order1 = create(:order, payment_method: "mobile_payment")
    pi1 = Payments::CreatePaymentIntent.call(order: order1)
    Payments::SubmitMobilePayment.call(payment_intent: pi1, reference: "RISK-REF-1", amount: pi1.amount,
                                        paid_at: Time.current)

    order2 = create(:order, payment_method: "mobile_payment")
    pi2 = Payments::CreatePaymentIntent.call(order: order2)
    Payments::SubmitMobilePayment.call(payment_intent: pi2, reference: "RISK-REF-1", amount: pi2.amount,
                                        paid_at: Time.current)

    signal = FraudSignal.find_by(signal_type: "duplicate_mobile_payment_reference", order: order2)
    expect(signal).to be_present
    expect(signal.subject).to eq(order2.customer)

    decision = RiskDecision.find_by(subject: order2.customer, order: order2)
    expect(decision).to be_present
    expect(decision.decision).to eq("manual_review")
  end

  it "records a fraud signal for a client-reported simulated GPS location but does not auto-open a " \
     "review decision at medium severity" do
    courier = create(:courier)

    Deliveries::RecordLocationPing.call(
      courier: courier, latitude: 8.62, longitude: -70.21, device_recorded_at: Time.current, source: "gps",
      simulated_location_suspected: true
    )

    expect(FraudSignal.find_by(subject: courier, signal_type: "simulated_gps_location")).to be_present
    expect(RiskDecision.where(subject: courier)).not_to exist
  end

  it "does not flag a normal-speed sequence of pings" do
    courier = create(:courier)
    Deliveries::RecordLocationPing.call(courier: courier, latitude: 8.62, longitude: -70.21,
                                         device_recorded_at: 60.seconds.ago, source: "gps")
    Deliveries::RecordLocationPing.call(courier: courier, latitude: 8.6205, longitude: -70.2105,
                                         device_recorded_at: Time.current, source: "gps")

    expect(FraudSignal.where(subject: courier, signal_type: "impossible_geographic_speed")).not_to exist
  end

  it "flags an impossible-speed jump between two consecutive pings" do
    courier = create(:courier)
    Deliveries::RecordLocationPing.call(courier: courier, latitude: 8.62, longitude: -70.21,
                                         device_recorded_at: 5.seconds.ago, source: "gps")
    Deliveries::RecordLocationPing.call(courier: courier, latitude: 9.5, longitude: -71.5,
                                         device_recorded_at: Time.current, source: "gps")

    signal = FraudSignal.find_by(subject: courier, signal_type: "impossible_geographic_speed")
    expect(signal).to be_present
    expect(signal.evidence["implied_speed_kmh"]).to be > 150

    decision = RiskDecision.find_by(subject: courier)
    expect(decision).to be_present
    expect(decision.decision).to eq("manual_review")
    expect(decision.reasons["fraud_signal_id"]).to eq(signal.id)
  end

  it "records and reviews a risk decision" do
    customer = create(:customer)
    decision = Risk::Decide.call(subject: customer, decision: "manual_review", risk_score: 55.0,
                                  reasons: { signals: [ "duplicate_mobile_payment_reference" ] })
    expect(decision.reviewed_at).to be_nil

    admin = create(:user)
    decision.review!(reviewed_by: admin)
    expect(decision.reload.reviewed_by_user).to eq(admin)
  end
end
