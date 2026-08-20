class CreateCashHandovers < ActiveRecord::Migration[8.1]
  def change
    create_table :cash_handovers, id: :uuid do |t|
      t.references :courier, null: false, type: :uuid, foreign_key: true
      t.references :received_by_user, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.bigint :amount, null: false
      t.string :currency, null: false
      t.string :evidence_attachment_reference
      t.string :status, null: false, default: "pending"
      t.string :idempotency_key, null: false
      t.timestamptz :handed_over_at, null: false
      t.timestamptz :confirmed_at
      t.text :notes

      t.timestamps
    end

    add_index :cash_handovers, %i[courier_id idempotency_key], unique: true
    add_index :cash_handovers, :status

    add_check_constraint :cash_handovers, "amount > 0", name: "cash_handovers_amount_positive"
  end
end
