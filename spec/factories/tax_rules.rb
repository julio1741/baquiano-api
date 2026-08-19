FactoryBot.define do
  factory :tax_rule do
    sequence(:name) { |n| "Impuesto #{n}" }
    rate_basis_points { 1_600 }
    valid_from { Date.current }
  end
end
