class CreateCartItems < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_items, id: :uuid do |t|
      t.references :cart, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :product, null: false, type: :uuid, foreign_key: true
      t.references :product_variant, type: :uuid, foreign_key: true
      t.integer :quantity, null: false
      t.bigint :unit_price_amount_snapshot, null: false
      t.string :currency, null: false
      t.string :notes
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_check_constraint :cart_items, "quantity > 0", name: "cart_items_quantity_positive"
    add_check_constraint :cart_items, "unit_price_amount_snapshot >= 0", name: "cart_items_unit_price_non_negative"
  end
end
