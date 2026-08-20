class CreatePaymentTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_transactions, id: :uuid do |t|
      t.references :payment_intent, null: false, type: :uuid, foreign_key: true
      t.string :transaction_type, null: false
      t.string :status, null: false
      t.bigint :amount, null: false
      t.string :currency, null: false
      t.string :provider_transaction_id
      t.string :idempotency_key, null: false
      t.text :raw_response_encrypted
      t.timestamptz :occurred_at, null: false

      t.timestamps
    end

    add_index :payment_transactions, %i[payment_intent_id idempotency_key], unique: true
    add_index :payment_transactions, :provider_transaction_id, unique: true,
                                      where: "provider_transaction_id IS NOT NULL"

    add_check_constraint :payment_transactions, "amount >= 0", name: "payment_transactions_amount_non_negative"
  end
end
