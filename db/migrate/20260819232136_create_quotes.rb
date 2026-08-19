class CreateQuotes < ActiveRecord::Migration[8.1]
  def change
    create_table :quotes, id: :uuid do |t|
      t.references :cart, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :customer, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :branch, null: false, type: :uuid, foreign_key: true
      t.references :address, null: false, type: :uuid, foreign_key: true
      t.string :currency, null: false
      t.bigint :subtotal_amount, null: false
      t.bigint :discount_amount, null: false, default: 0
      t.bigint :tax_amount, null: false, default: 0
      t.bigint :delivery_fee_amount, null: false, default: 0
      t.bigint :service_fee_amount, null: false, default: 0
      t.bigint :total_amount, null: false
      t.references :exchange_rate, type: :uuid, foreign_key: true
      t.decimal :exchange_rate_value, precision: 20, scale: 10
      t.jsonb :pricing_snapshot, null: false, default: {}
      t.timestamptz :expires_at, null: false
      t.timestamptz :consumed_at
      t.string :idempotency_key, null: false

      t.timestamps
    end

    add_index :quotes, [ :customer_id, :idempotency_key ], unique: true

    add_check_constraint :quotes, "subtotal_amount >= 0", name: "quotes_subtotal_amount_non_negative"
    add_check_constraint :quotes, "total_amount >= 0", name: "quotes_total_amount_non_negative"
  end
end
