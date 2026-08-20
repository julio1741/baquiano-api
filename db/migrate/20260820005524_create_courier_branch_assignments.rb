class CreateCourierBranchAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :courier_branch_assignments, id: :uuid do |t|
      t.references :courier, null: false, type: :uuid, foreign_key: true
      t.references :branch, null: false, type: :uuid, foreign_key: true
      t.boolean :active, null: false, default: true
      t.timestamptz :starts_at, null: false
      t.timestamptz :ends_at

      t.timestamps
    end

    add_index :courier_branch_assignments, %i[courier_id branch_id]
  end
end
