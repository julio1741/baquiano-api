class AddForeignKeyOnDeliveryIdToOrders < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :orders, :deliveries
    add_index :orders, :delivery_id, unique: true, where: "delivery_id IS NOT NULL"
  end
end
