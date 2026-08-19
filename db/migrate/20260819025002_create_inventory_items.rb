class CreateInventoryItems < ActiveRecord::Migration[8.1]
  def change
    create_table :inventory_items, id: :uuid do |t|
      t.references :branch, null: false, type: :uuid, foreign_key: true
      t.references :product, type: :uuid, foreign_key: true
      t.references :product_variant, type: :uuid, foreign_key: true
      t.string :availability_status, null: false, default: "available"
      t.integer :quantity
      t.boolean :track_quantity, null: false, default: false
      t.timestamptz :unavailable_until
      t.references :updated_by_user, null: false, type: :uuid, foreign_key: { to_table: :users, on_delete: :restrict }
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :inventory_items, [ :branch_id, :product_id ], unique: true, where: "product_id IS NOT NULL"
    add_index :inventory_items, [ :branch_id, :product_variant_id ], unique: true, where: "product_variant_id IS NOT NULL"

    add_check_constraint :inventory_items,
                          "(product_id IS NOT NULL AND product_variant_id IS NULL) OR " \
                          "(product_id IS NULL AND product_variant_id IS NOT NULL)",
                          name: "inventory_items_exactly_one_target"
  end
end
