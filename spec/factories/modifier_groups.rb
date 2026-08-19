FactoryBot.define do
  factory :modifier_group do
    product
    sequence(:name) { |n| "Grupo #{n}" }
    minimum_selections { 0 }
    maximum_selections { 1 }
  end
end
