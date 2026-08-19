FactoryBot.define do
  factory :catalog do
    branch
    sequence(:name) { |n| "Catalogo #{n}" }
  end
end
