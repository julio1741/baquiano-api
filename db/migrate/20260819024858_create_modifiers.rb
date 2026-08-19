class CreateModifiers < ActiveRecord::Migration[8.1]
  def change
    create_table :modifiers, id: :uuid do |t|
      t.references :modifier_group, null: false, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.bigint :additional_price_amount, null: false, default: 0
      t.string :currency, null: false
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_check_constraint :modifiers, "additional_price_amount >= 0", name: "modifiers_additional_price_amount_non_negative"
  end
end
