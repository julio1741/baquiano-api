class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders, id: :uuid do |t|
      t.string :public_number, null: false
      t.references :customer, null: false, type: :uuid, foreign_key: { on_delete: :restrict }
      t.references :organization, null: false, type: :uuid, foreign_key: { on_delete: :restrict }
      t.references :merchant, null: false, type: :uuid, foreign_key: { on_delete: :restrict }
      t.references :branch, null: false, type: :uuid, foreign_key: { on_delete: :restrict }
      t.references :address, null: false, type: :uuid, foreign_key: { on_delete: :restrict }
      t.references :quote, null: false, type: :uuid, foreign_key: { on_delete: :restrict }
      # No FK yet: deliveries doesn't exist until Increment 5.
      t.uuid :delivery_id
      t.string :current_status, null: false, default: "placed"
      t.string :payment_status, null: false
      t.string :fulfillment_type, null: false, default: "delivery"
      t.string :delivery_model, null: false
      t.string :currency, null: false
      t.bigint :subtotal_amount, null: false
      t.bigint :discount_amount, null: false, default: 0
      t.bigint :tax_amount, null: false, default: 0
      t.bigint :delivery_fee_amount, null: false, default: 0
      t.bigint :service_fee_amount, null: false, default: 0
      t.bigint :total_amount, null: false
      t.references :exchange_rate, type: :uuid, foreign_key: true
      t.decimal :exchange_rate_value, precision: 20, scale: 10
      t.string :customer_notes
      t.string :merchant_notes
      t.timestamptz :placed_at, null: false
      t.timestamptz :merchant_accepted_at
      t.timestamptz :ready_at
      t.timestamptz :picked_up_at
      t.timestamptz :delivered_at
      t.timestamptz :cancelled_at
      t.string :cancellation_reason_code
      t.string :cancellation_notes
      t.jsonb :pricing_snapshot, null: false, default: {}
      t.jsonb :address_snapshot, null: false, default: {}
      t.jsonb :merchant_snapshot, null: false, default: {}
      t.string :idempotency_key, null: false
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :orders, :public_number, unique: true
    add_index :orders, [ :customer_id, :idempotency_key ], unique: true
    add_index :orders, :current_status

    add_check_constraint :orders, "subtotal_amount >= 0", name: "orders_subtotal_amount_non_negative"
    add_check_constraint :orders, "total_amount >= 0", name: "orders_total_amount_non_negative"
  end
end
