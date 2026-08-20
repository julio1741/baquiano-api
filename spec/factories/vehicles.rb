FactoryBot.define do
  factory :vehicle do
    courier
    vehicle_type { :motorcycle }
    brand { "Yamaha" }
    model { "YBR125" }
    sequence(:plate) { |n| format("ABC%03d", n) }
    active { true }
  end
end
