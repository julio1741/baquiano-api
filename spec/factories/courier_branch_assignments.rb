FactoryBot.define do
  factory :courier_branch_assignment do
    courier
    branch
    starts_at { Time.current }
  end
end
