class CreateCartItemModifiers < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_item_modifiers, id: :uuid do |t|
      t.references :cart_item, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :modifier, null: false, type: :uuid, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.bigint :additional_price_amount_snapshot, null: false
      t.string :currency, null: false

      t.timestamps
    end

    add_check_constraint :cart_item_modifiers, "quantity > 0", name: "cart_item_modifiers_quantity_positive"
    add_check_constraint :cart_item_modifiers, "additional_price_amount_snapshot >= 0",
                          name: "cart_item_modifiers_price_non_negative"
  end
end
