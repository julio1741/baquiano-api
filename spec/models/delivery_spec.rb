require "rails_helper"

RSpec.describe Delivery, type: :model do
  it "rejects a direct status write outside Deliveries::TransitionDelivery" do
    delivery = create(:delivery)

    expect { delivery.update!(status: "assigned") }.to raise_error(ActiveRecord::RecordNotSaved)
  end

  it "allows the status write once explicitly authorized" do
    delivery = create(:delivery)

    delivery.status_change_authorized = true
    delivery.update!(status: "assigned")

    expect(delivery.reload.status).to eq("assigned")
  end

  describe "#matches_pin?" do
    it "matches only the correct PIN, via its digest" do
      delivery = create(:delivery, delivery_pin_digest: BlindIndex.digest("4821"))

      expect(delivery.matches_pin?("4821")).to be true
      expect(delivery.matches_pin?("0000")).to be false
    end

    it "is false when there is no PIN set yet" do
      delivery = create(:delivery, delivery_pin_digest: nil)

      expect(delivery.matches_pin?("4821")).to be false
    end
  end
end
