require "rails_helper"

RSpec.describe Orders::AutoCancelUnacceptedOrdersJob, type: :job do
  it "cancels orders stuck in merchant_pending past the timeout and leaves everything else alone" do
    stale = create(:order, current_status: "merchant_pending", placed_at: 20.minutes.ago)
    still_within_timeout = create(:order, current_status: "merchant_pending", placed_at: 1.minute.ago)
    already_accepted = create(:order, current_status: "merchant_accepted", placed_at: 20.minutes.ago)

    described_class.perform_now

    expect(stale.reload.current_status).to eq("cancelled")
    expect(stale.cancellation_reason_code).to eq("merchant_acceptance_timeout")
    expect(still_within_timeout.reload.current_status).to eq("merchant_pending")
    expect(already_accepted.reload.current_status).to eq("merchant_accepted")
  end

  it "records a domain event and status history entry for each auto-cancellation" do
    stale = create(:order, current_status: "merchant_pending", placed_at: 20.minutes.ago)

    described_class.perform_now

    history = stale.order_status_histories.order(:occurred_at).last
    expect(history.actor_type).to eq("system")
    expect(history.to_status).to eq("cancelled")
    expect(DomainEvent.where(aggregate_id: stale.id, event_type: "OrderCancelled")).to exist
  end

  it "skips an order that was already moved on by someone else between query and processing" do
    raced = create(:order, current_status: "merchant_pending", placed_at: 20.minutes.ago)
    normal = create(:order, current_status: "merchant_pending", placed_at: 20.minutes.ago)
    allow(Orders::TransitionOrder).to receive(:call).and_call_original
    allow(Orders::TransitionOrder).to receive(:call).with(hash_including(order: raced))
      .and_raise(ConflictError.new("cannot transition", code: "invalid_transition"))

    expect { described_class.perform_now }.not_to raise_error

    expect(raced.reload.current_status).to eq("merchant_pending")
    expect(normal.reload.current_status).to eq("cancelled")
  end
end
