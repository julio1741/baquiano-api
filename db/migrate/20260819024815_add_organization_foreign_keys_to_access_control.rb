class AddOrganizationForeignKeysToAccessControl < ActiveRecord::Migration[8.1]
  def change
    add_foreign_key :roles, :organizations, on_delete: :restrict
    add_foreign_key :role_assignments, :organizations, on_delete: :restrict
    add_foreign_key :role_assignments, :branches, on_delete: :restrict
  end
end
