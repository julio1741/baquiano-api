FactoryBot.define do
  factory :device do
    user
    sequence(:installation_id) { |n| "installation-#{n}" }
    platform { :android }
    app_type { :customer }
  end
end
