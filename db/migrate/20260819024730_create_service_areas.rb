class CreateServiceAreas < ActiveRecord::Migration[8.1]
  def change
    create_table :service_areas, id: :uuid do |t|
      t.references :branch, type: :uuid, foreign_key: true
      t.references :city, null: false, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.multi_polygon :geometry, geographic: true, null: false
      t.boolean :active, null: false, default: true
      # No FK yet: delivery_fee_rules doesn't exist until Increment 3.
      t.uuid :delivery_fee_rule_id

      t.timestamps
    end

    add_index :service_areas, :geometry, using: :gist
  end
end
