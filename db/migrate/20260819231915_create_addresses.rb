class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses, id: :uuid do |t|
      t.references :customer, null: false, type: :uuid, foreign_key: { on_delete: :cascade }
      t.references :city, null: false, type: :uuid, foreign_key: true
      t.string :label
      t.string :recipient_name, null: false
      t.text :contact_phone_encrypted
      t.string :original_text, null: false
      t.string :normalized_text
      t.string :building
      t.string :floor
      t.string :apartment
      t.string :landmark
      t.string :delivery_instructions
      t.st_point :location, geographic: true, null: false
      t.float :location_accuracy_meters
      t.timestamptz :validated_at
      t.boolean :is_default, null: false, default: false
      t.timestamptz :archived_at

      t.timestamps
    end

    add_index :addresses, :customer_id, unique: true, where: "is_default", name: "index_addresses_one_default_per_customer"
    add_index :addresses, :location, using: :gist
  end
end
