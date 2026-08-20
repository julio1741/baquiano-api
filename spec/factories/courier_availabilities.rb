FactoryBot.define do
  factory :courier_availability do
    courier
    status { "online" }
    started_at { Time.current }
  end
end
