class CreateReconciliationItems < ActiveRecord::Migration[8.1]
  def change
    create_table :reconciliation_items, id: :uuid do |t|
      t.references :reconciliation_batch, null: false, type: :uuid, foreign_key: true
      t.references :payment_transaction, type: :uuid, foreign_key: true
      t.string :external_reference
      t.bigint :expected_amount, null: false
      t.bigint :actual_amount, null: false
      t.bigint :difference_amount, null: false
      t.string :currency, null: false
      t.string :status, null: false, default: "pending"
      t.string :resolution_code
      t.text :resolution_notes
      t.references :resolved_by_user, type: :uuid, foreign_key: { to_table: :users }
      t.timestamptz :resolved_at

      t.timestamps
    end

    add_index :reconciliation_items, :status
  end
end
