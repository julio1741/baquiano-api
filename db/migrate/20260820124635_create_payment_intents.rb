class CreatePaymentIntents < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_intents, id: :uuid do |t|
      t.references :order, null: false, type: :uuid, foreign_key: true, index: { unique: true }
      t.references :customer, null: false, type: :uuid, foreign_key: true
      t.string :provider, null: false, default: "manual"
      t.string :payment_method, null: false
      t.string :status, null: false, default: "created"
      t.bigint :amount, null: false
      t.string :currency, null: false
      t.string :provider_reference
      t.string :idempotency_key, null: false
      t.timestamptz :expires_at
      t.timestamptz :authorized_at
      t.timestamptz :captured_at
      t.timestamptz :failed_at
      t.string :failure_code
      t.string :failure_message
      t.jsonb :metadata, null: false, default: {}
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :payment_intents, :status
    add_index :payment_intents, %i[customer_id idempotency_key], unique: true

    add_check_constraint :payment_intents, "amount >= 0", name: "payment_intents_amount_non_negative"
  end
end
