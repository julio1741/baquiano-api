# Versioned, append-only per key: Configuration::SystemSettings always
# inserts a new row with an incremented version rather than updating one
# in place, so history is never lost.
class CreateSystemSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :system_settings, id: :uuid do |t|
      t.string :scope_type, null: false
      t.uuid :scope_id
      t.string :key, null: false
      t.jsonb :value, null: false
      t.string :value_type, null: false
      t.boolean :encrypted, null: false, default: false
      t.integer :version, null: false, default: 1
      t.timestamptz :effective_at, null: false
      t.timestamptz :expires_at
      t.references :updated_by_user, null: false, type: :uuid, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :system_settings, %i[scope_type scope_id key version], unique: true,
                                 name: "index_system_settings_on_scope_and_key_and_version"
  end
end
