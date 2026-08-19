class CreateCities < ActiveRecord::Migration[8.1]
  def change
    create_table :cities, id: :uuid do |t|
      t.string :name, null: false
      t.string :state_name, null: false
      t.string :country_code, null: false
      t.string :timezone, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :cities, [ :name, :state_name, :country_code ], unique: true
  end
end
