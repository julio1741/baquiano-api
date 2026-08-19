class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories, id: :uuid do |t|
      t.references :catalog, null: false, type: :uuid, foreign_key: true
      t.uuid :parent_category_id
      t.string :name, null: false
      t.string :description
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true
      t.timestamptz :available_from
      t.timestamptz :available_until

      t.timestamps
    end

    add_index :categories, :parent_category_id
    add_foreign_key :categories, :categories, column: :parent_category_id, on_delete: :nullify
  end
end
