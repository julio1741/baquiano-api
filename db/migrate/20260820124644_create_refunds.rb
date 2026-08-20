class CreateRefunds < ActiveRecord::Migration[8.1]
  def change
    create_table :refunds, id: :uuid do |t|
      t.references :order, null: false, type: :uuid, foreign_key: true
      t.references :payment_intent, null: false, type: :uuid, foreign_key: true
      t.references :requested_by_user, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.references :approved_by_user, type: :uuid, foreign_key: { to_table: :users }
      t.string :status, null: false, default: "requested"
      t.string :reason_code, null: false
      t.text :reason_notes
      t.bigint :amount, null: false
      t.string :currency, null: false
      t.string :idempotency_key, null: false
      t.string :provider_reference
      t.timestamptz :requested_at, null: false
      t.timestamptz :approved_at
      t.timestamptz :completed_at
      t.timestamptz :failed_at
      t.string :failure_code
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :refunds, %i[order_id idempotency_key], unique: true
    add_index :refunds, :status

    add_check_constraint :refunds, "amount > 0", name: "refunds_amount_positive"
  end
end
