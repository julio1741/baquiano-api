class CreatePosPaymentRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :pos_payment_records, id: :uuid do |t|
      t.references :payment_intent, null: false, type: :uuid, foreign_key: true
      t.string :terminal_owner_type
      t.uuid :terminal_owner_id
      t.text :terminal_identifier_encrypted
      t.text :acquiring_account_reference_encrypted
      t.string :receipt_reference
      t.bigint :amount, null: false
      t.string :currency, null: false
      t.string :status, null: false, default: "confirmed"
      t.references :confirmed_by_user, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.timestamptz :confirmed_at, null: false
      t.string :evidence_attachment_reference

      t.timestamps
    end

    add_index :pos_payment_records, %i[terminal_owner_type terminal_owner_id]

    add_check_constraint :pos_payment_records, "amount >= 0", name: "pos_payment_records_amount_non_negative"
  end
end
