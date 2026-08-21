class CreateWebhookEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :webhook_events, id: :uuid do |t|
      t.string :provider, null: false
      t.string :provider_event_id, null: false
      t.string :event_type
      t.boolean :signature_valid, null: false
      t.text :payload_encrypted, null: false
      t.string :status, null: false, default: "received"
      t.timestamptz :received_at, null: false
      t.timestamptz :processed_at
      t.integer :attempt_count, null: false, default: 0
      t.string :last_error

      t.timestamps
    end

    add_index :webhook_events, %i[provider provider_event_id], unique: true
    add_index :webhook_events, :status
  end
end
