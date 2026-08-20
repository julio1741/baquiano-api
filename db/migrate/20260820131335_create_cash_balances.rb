class CreateCashBalances < ActiveRecord::Migration[8.1]
  def change
    create_table :cash_balances, id: :uuid do |t|
      t.references :courier, null: false, type: :uuid, foreign_key: true
      t.string :currency, null: false
      t.bigint :amount_held, null: false, default: 0
      t.bigint :exposure_limit, null: false
      t.boolean :blocked_for_cash_orders, null: false, default: false
      t.timestamptz :calculated_at, null: false
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :cash_balances, %i[courier_id currency], unique: true

    add_check_constraint :cash_balances, "amount_held >= 0", name: "cash_balances_amount_held_non_negative"
  end
end
