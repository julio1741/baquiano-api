class CreateSupportCases < ActiveRecord::Migration[8.1]
  def change
    create_table :support_cases, id: :uuid do |t|
      t.string :public_number, null: false
      t.references :customer, type: :uuid, foreign_key: true
      t.references :order, type: :uuid, foreign_key: true
      t.references :delivery, type: :uuid, foreign_key: true
      t.references :opened_by_user, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.references :assigned_to_user, type: :uuid, foreign_key: { to_table: :users }
      t.string :category, null: false
      t.string :priority, null: false, default: "medium"
      t.string :status, null: false, default: "open"
      t.string :subject, null: false
      t.text :description, null: false
      t.text :resolution
      t.timestamptz :opened_at, null: false
      t.timestamptz :resolved_at
      t.timestamptz :closed_at
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :support_cases, :public_number, unique: true
    add_index :support_cases, :status
  end
end
