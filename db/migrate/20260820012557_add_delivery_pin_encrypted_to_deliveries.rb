class AddDeliveryPinEncryptedToDeliveries < ActiveRecord::Migration[8.1]
  def change
    add_column :deliveries, :delivery_pin_encrypted, :text
  end
end
