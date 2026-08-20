class CreateCourierAvailabilities < ActiveRecord::Migration[8.1]
  def change
    create_table :courier_availabilities, id: :uuid do |t|
      t.references :courier, null: false, type: :uuid, foreign_key: true
      t.string :status, null: false
      t.references :zone, type: :uuid, foreign_key: true
      t.timestamptz :started_at, null: false
      t.timestamptz :ended_at

      t.timestamps
    end

    # Only one open availability window (ended_at IS NULL) per courier at a time.
    add_index :courier_availabilities, :courier_id, unique: true, where: "ended_at IS NULL",
                                                     name: "index_courier_availabilities_on_open_window"
  end
end
