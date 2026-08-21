require "rails_helper"

RSpec.describe Deliveries::PurgeOldLocationPingsJob, type: :job do
  it "deletes only pings past the retention window" do
    courier = create(:courier)
    old_ping = create(:location_ping, courier: courier, server_received_at: 100.days.ago)
    recent_ping = create(:location_ping, courier: courier, server_received_at: 1.day.ago)

    described_class.perform_now

    expect(LocationPing.exists?(old_ping.id)).to be false
    expect(LocationPing.exists?(recent_ping.id)).to be true
  end
end
