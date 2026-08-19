class CreateProductVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :product_variants, id: :uuid do |t|
      t.references :product, null: false, type: :uuid, foreign_key: true
      t.string :sku, null: false
      t.string :name, null: false
      t.bigint :price_amount, null: false
      t.string :currency, null: false
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :product_variants, [ :product_id, :sku ], unique: true

    add_check_constraint :product_variants, "price_amount >= 0", name: "product_variants_price_amount_non_negative"
  end
end
