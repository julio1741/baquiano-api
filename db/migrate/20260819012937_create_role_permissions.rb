class CreateRolePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :role_permissions, id: :uuid do |t|
      t.references :role, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :permission, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.jsonb :conditions, null: false, default: {}

      t.datetime :created_at, null: false
    end

    add_index :role_permissions, [ :role_id, :permission_id ], unique: true
  end
end
