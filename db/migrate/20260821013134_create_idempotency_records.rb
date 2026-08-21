# Generic idempotency mechanism for new code going forward — most existing
# writes (Order, PaymentIntent, Refund, ...) already have their own
# bespoke idempotency_key column, which stays as-is (no retrofit). See
# docs/architecture/decisions.md.
class CreateIdempotencyRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :idempotency_records, id: :uuid do |t|
      t.string :key, null: false
      t.string :actor_type, null: false
      t.uuid :actor_id, null: false
      t.string :operation, null: false
      t.string :request_digest, null: false
      t.integer :response_status
      t.text :response_body_encrypted
      t.string :resource_type
      t.uuid :resource_id
      t.timestamptz :expires_at, null: false

      t.timestamps
    end

    add_index :idempotency_records, %i[actor_type actor_id operation key], unique: true,
                                     name: "index_idempotency_records_on_actor_and_operation_and_key"
  end
end
