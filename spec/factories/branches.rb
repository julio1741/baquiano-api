FactoryBot.define do
  factory :branch do
    organization
    merchant { association :merchant, organization: organization }
    sequence(:name) { |n| "Sucursal #{n}" }
    sequence(:slug) { |n| "sucursal-#{n}" }
    delivery_model { :baquiano }
    address_text { "Av. Bolivar, Barinas" }
    location { RGeo::Geographic.spherical_factory(srid: 4326).point(-70.2, 8.6) }
  end
end
