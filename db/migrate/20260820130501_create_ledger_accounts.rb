class CreateLedgerAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :ledger_accounts, id: :uuid do |t|
      t.references :organization, type: :uuid, foreign_key: true
      t.string :owner_type
      t.uuid :owner_id
      t.string :account_code, null: false
      t.string :account_type, null: false
      t.string :currency, null: false
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :ledger_accounts, :account_code, unique: true
    add_index :ledger_accounts, %i[owner_type owner_id]
  end
end
