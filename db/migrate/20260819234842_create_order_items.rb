class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items, id: :uuid do |t|
      t.references :order, null: false, type: :uuid, foreign_key: { on_delete: :restrict }
      t.references :source_product, type: :uuid, foreign_key: { to_table: :products, on_delete: :nullify }
      t.references :source_variant, type: :uuid, foreign_key: { to_table: :product_variants, on_delete: :nullify }
      t.string :sku_snapshot, null: false
      t.string :name_snapshot, null: false
      t.string :description_snapshot
      t.string :variant_name_snapshot
      t.integer :quantity, null: false
      t.bigint :unit_price_amount, null: false
      t.bigint :tax_amount, null: false, default: 0
      t.bigint :discount_amount, null: false, default: 0
      t.bigint :line_total_amount, null: false
      t.string :currency, null: false
      t.string :notes
      t.jsonb :product_snapshot, null: false, default: {}

      t.datetime :created_at, null: false
    end

    add_check_constraint :order_items, "quantity > 0", name: "order_items_quantity_positive"
    add_check_constraint :order_items, "line_total_amount >= 0", name: "order_items_line_total_non_negative"
  end
end
