FactoryBot.define do
  factory :system_setting do
    scope_type { "Platform" }
    key { "test_setting" }
    value { { "enabled" => true } }
    value_type { "json" }
    effective_at { Time.current }
    updated_by_user { association :user }
  end
end
