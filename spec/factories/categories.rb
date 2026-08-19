FactoryBot.define do
  factory :category do
    catalog
    sequence(:name) { |n| "Categoria #{n}" }
  end
end
