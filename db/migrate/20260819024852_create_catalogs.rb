class CreateCatalogs < ActiveRecord::Migration[8.1]
  def change
    create_table :catalogs, id: :uuid do |t|
      t.references :branch, null: false, type: :uuid, foreign_key: true
      t.string :name, null: false
      t.string :status, null: false, default: "draft"
      t.timestamptz :published_at
      t.integer :version, null: false, default: 1
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end
  end
end
