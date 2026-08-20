class CreateVehicles < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicles, id: :uuid do |t|
      t.references :courier, null: false, type: :uuid, foreign_key: true
      t.string :vehicle_type, null: false
      t.string :brand
      t.string :model
      t.string :color
      t.text :plate_encrypted
      t.string :plate_digest
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :vehicles, :plate_digest
  end
end
