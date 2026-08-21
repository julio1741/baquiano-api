require "rails_helper"

RSpec.describe "Webhooks::ProcessJob and Webhooks::RetryFailedJob", type: :job do
  it "ProcessJob moves a received event to processed" do
    event = create(:webhook_event, status: "received")
    Webhooks::ProcessJob.perform_now(event.id)
    expect(event.reload.status).to eq("processed")
  end

  it "RetryFailedJob is a no-op on an already-processed event" do
    event = create(:webhook_event, status: "processed", processed_at: Time.current)
    Webhooks::RetryFailedJob.perform_now
    expect(event.reload.status).to eq("processed")
  end

  it "RetryFailedJob reprocesses a stuck 'received' event" do
    event = create(:webhook_event, status: "received")
    Webhooks::RetryFailedJob.perform_now
    expect(event.reload.status).to eq("processed")
  end
end
