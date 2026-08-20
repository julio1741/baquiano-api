class CreateCouriers < ActiveRecord::Migration[8.1]
  def change
    create_table :couriers, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true, index: { unique: true }
      t.references :organization, type: :uuid, foreign_key: true
      t.string :courier_type, null: false
      t.string :status, null: false, default: "pending"
      t.string :approval_status, null: false, default: "pending"
      t.string :risk_level, null: false, default: "standard"
      t.boolean :cash_enabled, null: false, default: false
      t.bigint :maximum_cash_exposure
      t.timestamptz :approved_at
      t.timestamptz :suspended_at
      t.string :suspension_reason
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :couriers, :status
    add_index :couriers, :approval_status

    add_check_constraint :couriers, "maximum_cash_exposure IS NULL OR maximum_cash_exposure >= 0",
                          name: "couriers_maximum_cash_exposure_non_negative"
  end
end
