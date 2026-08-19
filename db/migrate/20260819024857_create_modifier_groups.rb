class CreateModifierGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :modifier_groups, id: :uuid do |t|
      t.references :product, null: false, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.integer :minimum_selections, null: false, default: 0
      t.integer :maximum_selections, null: false
      t.boolean :required, null: false, default: false
      t.integer :position, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_check_constraint :modifier_groups, "minimum_selections >= 0", name: "modifier_groups_minimum_selections_non_negative"
    add_check_constraint :modifier_groups, "maximum_selections >= minimum_selections",
                          name: "modifier_groups_maximum_gte_minimum"
  end
end
