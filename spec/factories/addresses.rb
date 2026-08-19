FactoryBot.define do
  factory :address do
    customer
    city
    recipient_name { "Julio Baptista" }
    original_text { "Av. Bolivar, Barinas" }
    location { RGeo::Geographic.spherical_factory(srid: 4326).point(-70.21, 8.61) }
  end
end
