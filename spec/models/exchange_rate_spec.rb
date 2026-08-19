require "rails_helper"

RSpec.describe ExchangeRate, type: :model do
  describe "#convert" do
    it "applies the rational rate without floating-point rounding" do
      rate = create(:exchange_rate, rate_numerator: 36_500_000, rate_denominator: 1_000_000)

      expect(rate.convert(100_00)).to eq(365_000)
    end
  end

  it "rejects a non-positive numerator or denominator" do
    expect(build(:exchange_rate, rate_numerator: 0)).not_to be_valid
    expect(build(:exchange_rate, rate_denominator: 0)).not_to be_valid
  end
end
