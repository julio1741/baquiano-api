FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "Role #{n}" }
    sequence(:code) { |n| "role_#{n}" }
    scope_type { :platform }

    trait :organization_scoped do
      scope_type { :organization }
      organization_id { SecureRandom.uuid }
    end

    trait :branch_scoped do
      scope_type { :branch }
      organization_id { SecureRandom.uuid }
    end
  end
end
