class CreateDeliveryFeeRules < ActiveRecord::Migration[8.1]
  def change
    create_table :delivery_fee_rules, id: :uuid do |t|
      t.references :city, null: false, type: :uuid, foreign_key: true
      t.references :zone, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.string :calculation_type, null: false
      t.bigint :base_amount, null: false
      t.bigint :per_kilometer_amount
      t.bigint :minimum_amount
      t.bigint :maximum_amount
      t.string :currency, null: false
      t.boolean :active, null: false, default: true
      t.date :valid_from, null: false
      t.date :valid_until
      t.jsonb :configuration, null: false, default: {}

      t.timestamps
    end

    add_check_constraint :delivery_fee_rules, "base_amount >= 0", name: "delivery_fee_rules_base_amount_non_negative"
  end
end
