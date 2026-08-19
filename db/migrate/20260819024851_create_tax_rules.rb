class CreateTaxRules < ActiveRecord::Migration[8.1]
  def change
    create_table :tax_rules, id: :uuid do |t|
      t.references :organization, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.integer :rate_basis_points, null: false
      t.boolean :inclusive, null: false, default: true
      t.boolean :active, null: false, default: true
      t.date :valid_from, null: false
      t.date :valid_until

      t.timestamps
    end

    add_check_constraint :tax_rules, "rate_basis_points BETWEEN 0 AND 10000", name: "tax_rules_rate_basis_points_range"
  end
end
