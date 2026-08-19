class CreateZones < ActiveRecord::Migration[8.1]
  def change
    create_table :zones, id: :uuid do |t|
      t.references :city, null: false, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.string :code, null: false
      t.multi_polygon :geometry, geographic: true, null: false
      t.boolean :active, null: false, default: true
      t.string :risk_level, null: false, default: "standard"

      t.timestamps
    end

    add_index :zones, [ :city_id, :code ], unique: true
    add_index :zones, :geometry, using: :gist
  end
end
