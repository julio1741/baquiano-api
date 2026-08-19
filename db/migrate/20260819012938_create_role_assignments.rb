class CreateRoleAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :role_assignments, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :role, null: false, type: :uuid, foreign_key: { on_delete: :restrict }
      # No FK yet: organizations/branches don't exist until Increment 2.
      # Added in db/migrate/*_add_organizations_foreign_keys_to_access_control.rb.
      t.uuid :organization_id
      t.uuid :branch_id
      t.timestamptz :starts_at, null: false
      t.timestamptz :expires_at
      t.references :assigned_by_user, null: false, type: :uuid, foreign_key: { to_table: :users, on_delete: :restrict }
      t.timestamptz :revoked_at
      t.references :revoked_by_user, type: :uuid, foreign_key: { to_table: :users, on_delete: :restrict }
      t.string :revocation_reason

      t.timestamps
    end

    add_index :role_assignments, :organization_id
    add_index :role_assignments, :branch_id
    add_index :role_assignments, [ :user_id, :role_id, :organization_id, :branch_id ],
              unique: true, where: "revoked_at IS NULL", name: "index_role_assignments_on_active_scope"
  end
end
