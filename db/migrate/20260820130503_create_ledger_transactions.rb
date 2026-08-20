# Append-only (section 4.11: "Debe ser append-only") — no updated_at.
class CreateLedgerTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_transactions, id: :uuid do |t|
      t.string :transaction_type, null: false
      t.string :reference_type, null: false
      t.uuid :reference_id, null: false
      t.string :description
      t.string :idempotency_key, null: false
      t.timestamptz :effective_at, null: false
      t.timestamptz :posted_at, null: false
      t.references :reversal_of_transaction, type: :uuid, foreign_key: { to_table: :ledger_transactions }
      t.references :created_by_user, type: :uuid, foreign_key: { to_table: :users }
      t.jsonb :metadata, null: false, default: {}

      t.datetime :created_at, null: false
    end

    add_index :ledger_transactions, :idempotency_key, unique: true
    add_index :ledger_transactions, %i[reference_type reference_id]
  end
end
