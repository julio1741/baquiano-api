require "rails_helper"

RSpec.describe Address, type: :model do
  it "unsets the previous default when a new address becomes the default" do
    customer = create(:customer)
    first = create(:address, customer: customer, is_default: true)

    second = create(:address, customer: customer, is_default: true)

    expect(first.reload.is_default).to be(false)
    expect(second.reload.is_default).to be(true)
  end

  it "does not affect another customer's default" do
    mine = create(:address, is_default: true)
    someone_elses = create(:address, is_default: true)

    expect(mine.reload.is_default).to be(true)
    expect(someone_elses.reload.is_default).to be(true)
  end

  describe "#covered?" do
    it "is false with no service area, true once one covers the point" do
      address = create(:address, location: RGeo::Geographic.spherical_factory(srid: 4326).point(-70.20, 8.65))
      expect(address.covered?).to be(false)

      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      ring = factory.linear_ring([
        factory.point(-70.30, 8.60), factory.point(-70.10, 8.60),
        factory.point(-70.10, 8.70), factory.point(-70.30, 8.70), factory.point(-70.30, 8.60)
      ])
      create(:service_area, geometry: factory.multi_polygon([ factory.polygon(ring) ]))

      expect(address.covered?).to be(true)
    end
  end
end
