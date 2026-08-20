class CreateDispatchOffers < ActiveRecord::Migration[8.1]
  def change
    create_table :dispatch_offers, id: :uuid do |t|
      t.references :delivery, null: false, type: :uuid, foreign_key: true
      t.references :courier, null: false, type: :uuid, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.timestamptz :offered_at, null: false
      t.timestamptz :expires_at, null: false
      t.timestamptz :responded_at
      t.string :rejection_reason
      t.jsonb :score_snapshot, null: false, default: {}
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :dispatch_offers, %i[delivery_id courier_id]
    add_index :dispatch_offers, :status
    # Only one offer may ever win a delivery's assignment.
    add_index :dispatch_offers, :delivery_id, unique: true, where: "status = 'accepted'",
                                               name: "index_dispatch_offers_on_accepted_delivery"
  end
end
