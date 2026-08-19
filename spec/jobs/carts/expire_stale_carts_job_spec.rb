require "rails_helper"

RSpec.describe Carts::ExpireStaleCartsJob, type: :job do
  it "expires active carts past their TTL and leaves everything else alone" do
    stale = create(:cart, status: "active", expires_at: 1.minute.ago)
    still_active = create(:cart, status: "active", expires_at: 1.hour.from_now)
    already_converted = create(:cart, status: "converted", expires_at: 1.minute.ago)

    described_class.perform_now

    expect(stale.reload.status).to eq("expired")
    expect(still_active.reload.status).to eq("active")
    expect(already_converted.reload.status).to eq("converted")
  end
end
