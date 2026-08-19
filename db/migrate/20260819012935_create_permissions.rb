class CreatePermissions < ActiveRecord::Migration[8.1]
  def change
    create_table :permissions, id: :uuid do |t|
      t.string :resource, null: false
      t.string :action, null: false
      t.string :code, null: false
      t.string :description
      t.boolean :sensitive, null: false, default: false

      t.timestamps
    end

    add_index :permissions, :code, unique: true
    add_index :permissions, [ :resource, :action ], unique: true
  end
end
