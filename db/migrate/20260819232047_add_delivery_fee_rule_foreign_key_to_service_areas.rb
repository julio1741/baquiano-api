class AddDeliveryFeeRuleForeignKeyToServiceAreas < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :service_areas, :delivery_fee_rules, on_delete: :nullify
  end
end
