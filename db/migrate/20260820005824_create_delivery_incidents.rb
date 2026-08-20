class CreateDeliveryIncidents < ActiveRecord::Migration[8.1]
  def change
    create_table :delivery_incidents, id: :uuid do |t|
      t.references :delivery, null: false, type: :uuid, foreign_key: true
      t.references :order, null: false, type: :uuid, foreign_key: true
      t.references :reported_by_user, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.string :incident_type, null: false
      t.string :severity, null: false
      t.string :status, null: false, default: "open"
      t.text :description, null: false
      t.text :resolution
      t.references :resolved_by_user, type: :uuid, foreign_key: { to_table: :users }
      t.timestamptz :occurred_at, null: false
      t.timestamptz :resolved_at

      t.timestamps
    end

    add_index :delivery_incidents, :status
  end
end
