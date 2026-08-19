FactoryBot.define do
  factory :inventory_item do
    branch
    product
    updated_by_user { association :user }
    availability_status { "available" }
  end
end
