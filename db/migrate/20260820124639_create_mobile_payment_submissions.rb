class CreateMobilePaymentSubmissions < ActiveRecord::Migration[8.1]
  def change
    create_table :mobile_payment_submissions, id: :uuid do |t|
      t.references :payment_intent, null: false, type: :uuid, foreign_key: true
      t.string :origin_bank_code
      t.string :destination_bank_code
      t.string :reference, null: false
      t.string :reference_digest, null: false
      t.string :payer_document_masked
      t.string :payer_phone_masked
      t.bigint :amount, null: false
      t.string :currency, null: false
      t.timestamptz :paid_at, null: false
      t.string :evidence_attachment_reference
      t.string :review_status, null: false, default: "submitted"
      t.references :reviewed_by_user, type: :uuid, foreign_key: { to_table: :users }
      t.timestamptz :reviewed_at
      t.string :rejection_reason
      t.references :duplicate_of_submission, type: :uuid, foreign_key: { to_table: :mobile_payment_submissions }
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    # Not a hard unique constraint: a reused reference is meant to be
    # recorded and flagged review_status="duplicate" (section 4.17's fraud
    # signal), not rejected at the database level.
    add_index :mobile_payment_submissions, :reference_digest
    add_index :mobile_payment_submissions, :review_status

    add_check_constraint :mobile_payment_submissions, "amount >= 0",
                          name: "mobile_payment_submissions_amount_non_negative"
  end
end
