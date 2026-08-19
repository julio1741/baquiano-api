class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles, id: :uuid do |t|
      # No FK yet: organizations doesn't exist until Increment 2. Added in
      # db/migrate/*_add_organizations_foreign_keys_to_access_control.rb.
      t.uuid :organization_id
      t.string :name, null: false
      t.string :code, null: false
      t.string :description
      t.string :scope_type, null: false
      t.boolean :system_role, null: false, default: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    # A plain unique index on (organization_id, code) wouldn't catch duplicate
    # codes among global roles: Postgres treats NULL organization_id values
    # as distinct from each other, so it needs a separate partial index.
    add_index :roles, [ :organization_id, :code ], unique: true, where: "organization_id IS NOT NULL",
                                                    name: "index_roles_on_organization_id_and_code"
    add_index :roles, :code, unique: true, where: "organization_id IS NULL", name: "index_roles_on_code_when_global"
  end
end
