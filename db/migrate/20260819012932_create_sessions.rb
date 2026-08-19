class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :device, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.string :refresh_token_digest, null: false
      t.inet :ip_address
      t.string :user_agent
      t.timestamptz :expires_at, null: false
      t.timestamptz :revoked_at
      t.uuid :rotated_from_session_id
      t.timestamptz :last_used_at

      t.timestamps
    end

    add_index :sessions, :refresh_token_digest, unique: true
    add_index :sessions, :rotated_from_session_id
    add_foreign_key :sessions, :sessions, column: :rotated_from_session_id, on_delete: :nullify
  end
end
