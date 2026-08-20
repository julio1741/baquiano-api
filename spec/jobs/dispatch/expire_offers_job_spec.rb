require "rails_helper"

RSpec.describe Dispatch::ExpireOffersJob, type: :job do
  it "expires a stale pending offer on a still-searching delivery" do
    delivery = create(:delivery, status: "offered")
    stale = create(:dispatch_offer, delivery: delivery, expires_at: 1.minute.ago)

    described_class.perform_now

    expect(stale.reload.status).to eq("expired")
  end

  it "cancels (not expires) a stale offer whose delivery already moved on" do
    delivery = create(:delivery, status: "accepted")
    stale = create(:dispatch_offer, delivery: delivery, expires_at: 1.minute.ago)

    described_class.perform_now

    expect(stale.reload.status).to eq("cancelled")
  end

  it "leaves a still-valid pending offer untouched" do
    delivery = create(:delivery, status: "offered")
    fresh = create(:dispatch_offer, delivery: delivery, expires_at: 1.minute.from_now)

    described_class.perform_now

    expect(fresh.reload.status).to eq("pending")
  end

  it "retries dispatch for a delivery left with zero pending offers" do
    branch = create(:branch)
    order = create(:order, branch: branch, organization: branch.organization, merchant: branch.merchant)
    delivery = create(:delivery, order: order, branch: branch, status: "offered")
    create(:dispatch_offer, delivery: delivery, expires_at: 1.minute.ago)

    courier = create(:courier, status: "active", approval_status: "approved")
    create(:courier_availability, courier: courier, status: "online")
    create(:location_ping, courier: courier, location: branch.location)

    described_class.perform_now

    expect(delivery.dispatch_offers.where(status: "pending").count).to eq(1)
    expect(delivery.dispatch_offers.pending.first.courier_id).to eq(courier.id)
  end

  it "is safe to run when no couriers are available for a retry" do
    delivery = create(:delivery, status: "offered")
    create(:dispatch_offer, delivery: delivery, expires_at: 1.minute.ago)

    expect { described_class.perform_now }.not_to raise_error
  end
end
