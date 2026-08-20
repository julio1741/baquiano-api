FactoryBot.define do
  factory :ledger_entry do
    ledger_transaction
    ledger_account
    direction { "debit" }
    amount { 1_000 }
    currency { "VES" }
  end
end
