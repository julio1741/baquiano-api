class CreateOrganizations < ActiveRecord::Migration[8.1]
  def change
    create_table :organizations, id: :uuid do |t|
      t.string :legal_name, null: false
      t.string :display_name, null: false
      t.string :organization_type, null: false
      t.text :tax_identifier_encrypted
      t.string :tax_identifier_digest
      t.string :status, null: false, default: "pending"
      t.string :default_currency, null: false
      t.text :contact_phone_encrypted
      t.text :contact_email_encrypted
      t.string :onboarding_status, null: false, default: "started"
      t.timestamptz :approved_at
      t.timestamptz :suspended_at
      t.string :suspension_reason
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :organizations, :tax_identifier_digest, unique: true, where: "tax_identifier_digest IS NOT NULL"
    add_index :organizations, :organization_type
    add_index :organizations, :status
  end
end
