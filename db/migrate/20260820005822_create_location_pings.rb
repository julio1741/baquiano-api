class CreateLocationPings < ActiveRecord::Migration[8.1]
  def change
    create_table :location_pings, id: :uuid do |t|
      t.references :courier, null: false, type: :uuid, foreign_key: true
      t.references :delivery, type: :uuid, foreign_key: true
      t.st_point :location, geographic: true, null: false
      t.timestamptz :device_recorded_at, null: false
      t.timestamptz :server_received_at, null: false
      t.decimal :accuracy_meters, precision: 8, scale: 2
      t.decimal :speed_meters_per_second, precision: 8, scale: 2
      t.decimal :heading_degrees, precision: 5, scale: 2
      t.string :source, null: false
      t.boolean :simulated_location_suspected, null: false, default: false
      t.jsonb :anomaly_flags, null: false, default: {}

      t.datetime :created_at, null: false
    end

    add_index :location_pings, :location, using: :gist
    add_index :location_pings, %i[courier_id server_received_at]
  end
end
