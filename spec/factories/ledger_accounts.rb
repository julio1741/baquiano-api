FactoryBot.define do
  factory :ledger_account do
    sequence(:account_code) { |n| "test:account:#{n}" }
    account_type { "asset" }
    currency { "VES" }
  end
end
