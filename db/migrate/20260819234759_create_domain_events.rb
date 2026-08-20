class CreateDomainEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :domain_events, id: :uuid do |t|
      t.string :aggregate_type, null: false
      t.uuid :aggregate_id, null: false
      t.string :event_type, null: false
      t.integer :event_version, null: false, default: 1
      t.jsonb :payload, null: false, default: {}
      t.timestamptz :occurred_at, null: false
      t.uuid :correlation_id, null: false
      t.uuid :causation_id

      t.datetime :created_at, null: false
    end

    add_index :domain_events, [ :aggregate_type, :aggregate_id ]
    add_index :domain_events, :event_type
    add_index :domain_events, :correlation_id
  end
end
