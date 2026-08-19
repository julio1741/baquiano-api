class CreateBranches < ActiveRecord::Migration[8.1]
  def change
    create_table :branches, id: :uuid do |t|
      t.references :organization, null: false, type: :uuid, foreign_key: true
      t.references :merchant, null: false, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.string :slug, null: false
      t.text :phone_encrypted
      t.text :email_encrypted
      t.string :status, null: false, default: "pending"
      t.string :delivery_model, null: false
      t.string :address_text, null: false
      t.string :address_reference
      t.st_point :location, geographic: true, null: false
      t.integer :preparation_time_minutes
      t.bigint :minimum_order_amount
      t.string :minimum_order_currency
      t.boolean :accepts_cash, null: false, default: false
      t.boolean :accepts_mobile_payment, null: false, default: true
      t.boolean :accepts_pos_on_delivery, null: false, default: false
      t.timestamptz :paused_at
      t.string :pause_reason
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :branches, [ :organization_id, :slug ], unique: true
    add_index :branches, :location, using: :gist
    add_index :branches, :status

    add_check_constraint :branches, "minimum_order_amount IS NULL OR minimum_order_amount >= 0",
                          name: "branches_minimum_order_amount_non_negative"
    add_check_constraint :branches, "preparation_time_minutes IS NULL OR preparation_time_minutes > 0",
                          name: "branches_preparation_time_minutes_positive"
  end
end
