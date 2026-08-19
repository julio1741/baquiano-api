class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products, id: :uuid do |t|
      t.references :catalog, null: false, type: :uuid, foreign_key: true
      t.references :category, null: false, type: :uuid, foreign_key: true
      t.string :sku, null: false
      t.string :name, null: false
      t.string :description
      t.string :product_type, null: false
      t.bigint :base_price_amount, null: false
      t.string :currency, null: false
      t.references :tax_rule, type: :uuid, foreign_key: true
      t.string :image_attachment_reference
      t.boolean :active, null: false, default: true
      t.boolean :age_restricted, null: false, default: false
      t.boolean :prescription_required, null: false, default: false
      t.integer :preparation_time_minutes
      t.timestamptz :available_from
      t.timestamptz :available_until
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :products, [ :catalog_id, :sku ], unique: true

    add_check_constraint :products, "base_price_amount >= 0", name: "products_base_price_amount_non_negative"
  end
end
