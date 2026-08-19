class CreateBusinessHours < ActiveRecord::Migration[8.1]
  def change
    create_table :business_hours, id: :uuid do |t|
      t.references :branch, null: false, type: :uuid, foreign_key: true
      t.integer :day_of_week, null: false
      t.time :opens_at, null: false
      t.time :closes_at, null: false
      t.boolean :crosses_midnight, null: false, default: false

      t.timestamps
    end

    add_index :business_hours, [ :branch_id, :day_of_week, :opens_at ], unique: true, name: "index_business_hours_uniqueness"

    add_check_constraint :business_hours, "day_of_week BETWEEN 0 AND 6", name: "business_hours_day_of_week_range"
  end
end
