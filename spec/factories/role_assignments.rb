FactoryBot.define do
  factory :role_assignment do
    user
    role
    assigned_by_user { association :user }
    starts_at { Time.current }
  end
end
