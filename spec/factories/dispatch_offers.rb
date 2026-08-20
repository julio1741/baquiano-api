FactoryBot.define do
  factory :dispatch_offer do
    delivery
    courier
    status { "pending" }
    offered_at { Time.current }
    expires_at { 30.seconds.from_now }
  end
end
