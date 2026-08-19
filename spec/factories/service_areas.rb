FactoryBot.define do
  factory :service_area do
    city
    branch { nil }
    sequence(:name) { |n| "Cobertura #{n}" }
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
