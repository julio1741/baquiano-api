class CreateCustomers < ActiveRecord::Migration[8.1]
  def change
    create_table :customers, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: { on_delete: :cascade }, index: { unique: true }
      t.string :status, null: false, default: "active"
      # No FK yet: addresses doesn't exist until later in this same increment.
      # See db/migrate/*_add_default_address_foreign_key_to_customers.rb.
      t.uuid :default_address_id
      t.string :risk_level, null: false, default: "standard"
      t.integer :total_completed_orders, null: false, default: 0
      t.timestamptz :last_order_at
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_check_constraint :customers, "total_completed_orders >= 0", name: "customers_total_completed_orders_non_negative"
  end
end
