class AddDefaultAddressForeignKeyToCustomers < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :customers, :addresses, column: :default_address_id, on_delete: :nullify
  end
end
