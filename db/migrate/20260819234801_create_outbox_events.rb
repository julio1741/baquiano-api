class CreateOutboxEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :outbox_events, id: :uuid do |t|
      t.string :event_type, null: false
      t.string :aggregate_type, null: false
      t.uuid :aggregate_id, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :status, null: false, default: "pending"
      t.timestamptz :available_at, null: false
      t.timestamptz :published_at
      t.integer :attempt_count, null: false, default: 0
      t.string :last_error

      t.timestamps
    end

    add_index :outbox_events, [ :status, :available_at ]
  end
end
