class CreateFeatureFlags < ActiveRecord::Migration[8.1]
  def change
    create_table :feature_flags, id: :uuid do |t|
      t.string :key, null: false
      t.string :description
      t.boolean :enabled, null: false, default: false
      t.jsonb :rules, null: false, default: {}
      t.references :created_by_user, null: false, type: :uuid, foreign_key: { to_table: :users }
      t.references :updated_by_user, null: false, type: :uuid, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :feature_flags, :key, unique: true
  end
end
