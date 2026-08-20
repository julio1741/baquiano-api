class CreateOrderTransitionRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :order_transition_requests, id: :uuid do |t|
      t.references :order, null: false, type: :uuid, foreign_key: { on_delete: :restrict }
      t.string :requested_transition, null: false
      t.references :requested_by_user, null: false, type: :uuid, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :idempotency_key, null: false
      t.string :status, null: false, default: "pending"
      t.string :failure_code
      t.string :failure_message
      t.timestamptz :processed_at

      t.timestamps
    end

    add_index :order_transition_requests, [ :order_id, :idempotency_key ], unique: true
  end
end
