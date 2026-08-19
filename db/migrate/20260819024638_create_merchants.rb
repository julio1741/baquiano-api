class CreateMerchants < ActiveRecord::Migration[8.1]
  def change
    create_table :merchants, id: :uuid do |t|
      t.references :organization, null: false, type: :uuid, foreign_key: true
      t.string :slug, null: false
      t.string :description
      t.string :vertical, null: false
      t.string :logo_attachment_reference
      t.string :cover_attachment_reference
      t.string :status, null: false, default: "pending"
      # Commission fields are left unset until validated commercially — see
      # docs/architecture/decisions.md. Never assume a default rate.
      t.string :commission_type
      t.integer :commission_rate_basis_points
      t.bigint :commission_fixed_amount
      t.string :commission_currency
      t.boolean :accepts_baquiano_couriers, null: false, default: false
      t.boolean :accepts_own_couriers, null: false, default: false
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :merchants, :slug, unique: true
    add_index :merchants, :vertical

    add_check_constraint :merchants,
                          "commission_rate_basis_points IS NULL OR (commission_rate_basis_points BETWEEN 0 AND 10000)",
                          name: "merchants_commission_rate_basis_points_range"
  end
end
