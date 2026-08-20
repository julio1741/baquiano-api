class CreateDeliveries < ActiveRecord::Migration[8.1]
  def change
    create_table :deliveries, id: :uuid do |t|
      t.references :order, null: false, type: :uuid, foreign_key: true, index: { unique: true }
      t.references :courier, type: :uuid, foreign_key: true
      t.references :branch, null: false, type: :uuid, foreign_key: true
      t.string :delivery_model, null: false
      t.string :status, null: false, default: "pending_assignment"
      t.st_point :pickup_location, geographic: true, null: false
      t.st_point :dropoff_location, geographic: true, null: false
      t.integer :estimated_distance_meters
      t.integer :estimated_duration_seconds
      t.timestamptz :estimated_pickup_at
      t.timestamptz :estimated_delivery_at
      t.timestamptz :assigned_at
      t.timestamptz :accepted_at
      t.timestamptz :arrived_at_merchant_at
      t.timestamptz :picked_up_at
      t.timestamptz :arrived_at_customer_at
      t.timestamptz :delivered_at
      t.timestamptz :failed_at
      t.string :failure_reason
      t.string :delivery_pin_digest
      t.string :proof_of_pickup_attachment_reference
      t.string :proof_of_delivery_attachment_reference
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :deliveries, :status
    add_index :deliveries, :pickup_location, using: :gist
    add_index :deliveries, :dropoff_location, using: :gist

    add_check_constraint :deliveries, "estimated_distance_meters IS NULL OR estimated_distance_meters >= 0",
                          name: "deliveries_estimated_distance_meters_non_negative"
    add_check_constraint :deliveries, "estimated_duration_seconds IS NULL OR estimated_duration_seconds >= 0",
                          name: "deliveries_estimated_duration_seconds_non_negative"
  end
end
