FactoryBot.define do
  factory :courier do
    user
    courier_type { :baquiano }
    risk_level { "standard" }
  end
end
