class CreateUserIdentities < ActiveRecord::Migration[8.1]
  def change
    create_table :user_identities, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.string :provider, null: false
      t.string :provider_subject, null: false
      t.jsonb :provider_metadata, null: false, default: {}
      t.timestamptz :verified_at
      t.timestamptz :last_used_at

      t.timestamps
    end

    add_index :user_identities, [ :provider, :provider_subject ], unique: true
  end
end
