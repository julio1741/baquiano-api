class CreateDevices < ActiveRecord::Migration[8.1]
  def change
    create_table :devices, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.string :installation_id, null: false
      t.string :platform, null: false
      t.string :app_type, null: false
      t.string :app_version
      t.string :os_version
      t.string :device_model
      t.text :push_token_encrypted
      t.string :push_provider
      t.string :device_fingerprint_digest
      t.timestamptz :trusted_at
      t.timestamptz :blocked_at
      t.timestamptz :last_seen_at
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :devices, [ :user_id, :installation_id ], unique: true
  end
end
