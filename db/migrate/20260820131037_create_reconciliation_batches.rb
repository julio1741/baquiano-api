class CreateReconciliationBatches < ActiveRecord::Migration[8.1]
  def change
    create_table :reconciliation_batches, id: :uuid do |t|
      t.string :provider, null: false
      t.string :payment_method, null: false
      t.string :currency, null: false
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.string :status, null: false, default: "open"
      t.bigint :expected_amount, null: false, default: 0
      t.bigint :actual_amount, null: false, default: 0
      t.bigint :difference_amount, null: false, default: 0
      t.references :started_by_user, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.references :completed_by_user, type: :uuid, foreign_key: { to_table: :users }
      t.timestamptz :started_at, null: false
      t.timestamptz :completed_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :reconciliation_batches, :status
  end
end
