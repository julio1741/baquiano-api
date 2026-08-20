class CreateSettlements < ActiveRecord::Migration[8.1]
  def change
    create_table :settlements, id: :uuid do |t|
      t.string :beneficiary_type, null: false
      t.uuid :beneficiary_id, null: false
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.string :currency, null: false
      t.bigint :gross_amount, null: false
      t.bigint :commission_amount, null: false, default: 0
      t.bigint :adjustment_amount, null: false, default: 0
      t.bigint :net_amount, null: false
      t.string :status, null: false, default: "pending"
      t.references :approved_by_user, type: :uuid, foreign_key: { to_table: :users }
      t.timestamptz :paid_at
      t.text :payment_reference_encrypted
      t.string :idempotency_key, null: false
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :settlements, %i[beneficiary_type beneficiary_id]
    add_index :settlements, :idempotency_key, unique: true
    add_index :settlements, :status
  end
end
