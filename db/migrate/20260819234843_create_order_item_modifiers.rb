class CreateOrderItemModifiers < ActiveRecord::Migration[8.1]
  def change
    create_table :order_item_modifiers, id: :uuid do |t|
      t.references :order_item, null: false, type: :uuid, foreign_key: { on_delete: :restrict }
      t.references :source_modifier, type: :uuid, foreign_key: { to_table: :modifiers, on_delete: :nullify }
      t.string :modifier_group_name_snapshot, null: false
      t.string :modifier_name_snapshot, null: false
      t.integer :quantity, null: false, default: 1
      t.bigint :unit_price_amount, null: false
      t.bigint :total_amount, null: false
      t.string :currency, null: false

      t.datetime :created_at, null: false
    end

    add_check_constraint :order_item_modifiers, "quantity > 0", name: "order_item_modifiers_quantity_positive"
  end
end
