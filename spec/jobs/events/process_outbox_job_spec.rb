require "rails_helper"

RSpec.describe Events::ProcessOutboxJob, type: :job do
  it "publishes pending outbox events" do
    order = create(:order)
    Events::Publish.call(aggregate: order, event_type: "TestEvent", payload: {})
    outbox_event = OutboxEvent.where(aggregate_id: order.id).last
    expect(outbox_event.status).to eq("pending")

    described_class.perform_now

    expect(outbox_event.reload.status).to eq("published")
    expect(outbox_event.published_at).to be_present
  end

  it "does not touch an outbox event scheduled for the future" do
    order = create(:order)
    outbox_event = create(:outbox_event, aggregate_type: "Order", aggregate_id: order.id, status: "pending",
                                          available_at: 1.hour.from_now)

    described_class.perform_now

    expect(outbox_event.reload.status).to eq("pending")
  end
end
