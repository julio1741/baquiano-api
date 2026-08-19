require "rails_helper"

RSpec.describe DeliveryFeeRule, type: :model do
  describe "#fee_for" do
    it "returns a flat amount for a fixed rule" do
      rule = create(:delivery_fee_rule, calculation_type: "fixed", base_amount: 150)

      expect(rule.fee_for).to eq(150)
    end

    it "adds a per-kilometer amount for a distance rule" do
      rule = create(:delivery_fee_rule, calculation_type: "distance", base_amount: 100, per_kilometer_amount: 50)

      expect(rule.fee_for(distance_meters: 2_000)).to eq(200)
    end

    it "clamps to minimum_amount and maximum_amount" do
      rule = create(:delivery_fee_rule, calculation_type: "fixed", base_amount: 100, minimum_amount: 150,
                                        maximum_amount: 300)

      expect(rule.fee_for).to eq(150)
    end

    it "raises without a distance for a distance-based rule" do
      rule = create(:delivery_fee_rule, calculation_type: "distance", base_amount: 100, per_kilometer_amount: 50)

      expect { rule.fee_for }.to raise_error(ArgumentError)
    end
  end
end
