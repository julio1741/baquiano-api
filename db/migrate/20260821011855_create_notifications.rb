class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.references :order, type: :uuid, foreign_key: true
      t.string :channel, null: false
      t.string :template_code, null: false
      t.string :status, null: false, default: "pending"
      t.string :destination_digest
      t.jsonb :payload, null: false, default: {}
      t.string :provider, null: false, default: "log"
      t.string :provider_message_id
      t.timestamptz :scheduled_at, null: false
      t.timestamptz :sent_at
      t.timestamptz :delivered_at
      t.timestamptz :failed_at
      t.string :failure_code
      t.integer :attempt_count, null: false, default: 0
      t.string :idempotency_key, null: false

      t.timestamps
    end

    add_index :notifications, %i[user_id idempotency_key], unique: true
    add_index :notifications, :status
  end
end
