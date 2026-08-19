FactoryBot.define do
  factory :zone do
    city
    sequence(:name) { |n| "Zona #{n}" }
    sequence(:code) { |n| "zona-#{n}" }
    risk_level { "standard" }
    geometry do
      factory = RGeo::Geographic.spherical_factory(srid: 4326)
      ring = factory.linear_ring([
        factory.point(-70.30, 8.60),
        factory.point(-70.10, 8.60),
        factory.point(-70.10, 8.70),
        factory.point(-70.30, 8.70),
        factory.point(-70.30, 8.60)
      ])
      factory.multi_polygon([ factory.polygon(ring) ])
    end
  end
end
