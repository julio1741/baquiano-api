class CreateOrderStatusHistories < ActiveRecord::Migration[8.1]
  def change
    create_table :order_status_histories, id: :uuid do |t|
      t.references :order, null: false, type: :uuid, foreign_key: { on_delete: :restrict }
      t.string :from_status
      t.string :to_status, null: false
      t.references :actor_user, type: :uuid, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :actor_type, null: false
      t.string :reason_code
      t.string :notes
      t.jsonb :metadata, null: false, default: {}
      t.timestamptz :occurred_at, null: false

      t.datetime :created_at, null: false
    end

    add_index :order_status_histories, [ :order_id, :occurred_at ]
  end
end
