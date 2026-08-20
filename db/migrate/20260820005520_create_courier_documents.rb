class CreateCourierDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :courier_documents, id: :uuid do |t|
      t.references :courier, null: false, type: :uuid, foreign_key: true
      t.string :document_type, null: false
      t.string :attachment_reference, null: false
      t.text :document_number_encrypted
      t.string :document_number_digest
      t.string :status, null: false, default: "pending"
      t.timestamptz :expires_at
      t.references :reviewed_by_user, type: :uuid, foreign_key: { to_table: :users }
      t.timestamptz :reviewed_at
      t.string :rejection_reason

      t.timestamps
    end

    add_index :courier_documents, :status
    add_index :courier_documents, :document_number_digest
  end
end
