FactoryBot.define do
  factory :delivery do
    order
    branch { order.branch }
    delivery_model { "baquiano" }
    status { "pending_assignment" }
    pickup_location { RGeo::Geographic.spherical_factory(srid: 4326).point(-70.21, 8.62) }
    dropoff_location { RGeo::Geographic.spherical_factory(srid: 4326).point(-70.20, 8.61) }
  end
end
