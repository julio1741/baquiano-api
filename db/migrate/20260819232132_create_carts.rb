class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts, id: :uuid do |t|
      t.references :customer, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :branch, null: false, type: :uuid, foreign_key: true
      t.string :status, null: false, default: "active"
      t.string :currency, null: false
      t.timestamptz :expires_at, null: false
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :carts, [ :customer_id, :branch_id ], unique: true, where: "status = 'active'",
                                                     name: "index_carts_one_active_per_customer_and_branch"
  end
end
