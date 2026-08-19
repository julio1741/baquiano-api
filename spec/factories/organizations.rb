FactoryBot.define do
  factory :organization do
    sequence(:legal_name) { |n| "Comercio #{n} C.A." }
    sequence(:display_name) { |n| "Comercio #{n}" }
    organization_type { :merchant }
    default_currency { "VES" }
  end
end
