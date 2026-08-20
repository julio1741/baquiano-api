FactoryBot.define do
  factory :reconciliation_item do
    reconciliation_batch
    expected_amount { 1_000 }
    actual_amount { 1_000 }
    currency { "VES" }
  end
end
