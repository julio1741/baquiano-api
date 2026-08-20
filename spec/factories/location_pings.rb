FactoryBot.define do
  factory :location_ping do
    courier
    location { RGeo::Geographic.spherical_factory(srid: 4326).point(-70.21, 8.62) }
    device_recorded_at { Time.current }
    server_received_at { Time.current }
    source { "gps" }
  end
end
