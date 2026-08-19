class CreateSpecialBusinessHours < ActiveRecord::Migration[8.1]
  def change
    create_table :special_business_hours, id: :uuid do |t|
      t.references :branch, null: false, type: :uuid, foreign_key: true
      t.date :date, null: false
      t.boolean :is_closed, null: false, default: false
      t.time :opens_at
      t.time :closes_at
      t.string :reason

      t.timestamps
    end

    add_index :special_business_hours, [ :branch_id, :date ], unique: true
  end
end
