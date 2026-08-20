# Append-only, same as ledger_transactions.
class CreateLedgerEntries < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_entries, id: :uuid do |t|
      t.references :ledger_transaction, null: false, type: :uuid, foreign_key: true
      t.references :ledger_account, null: false, type: :uuid, foreign_key: true
      t.string :direction, null: false
      t.bigint :amount, null: false
      t.string :currency, null: false

      t.datetime :created_at, null: false
    end

    add_index :ledger_entries, :direction

    add_check_constraint :ledger_entries, "amount > 0", name: "ledger_entries_amount_positive"
  end
end
