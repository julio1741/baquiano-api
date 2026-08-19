class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.string :phone_country_code, null: false
      t.text :phone_number_encrypted, null: false
      t.string :phone_number_digest, null: false
      t.text :email_encrypted
      t.string :email_digest
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :preferred_language, null: false, default: "es"
      t.string :timezone, null: false, default: "America/Caracas"
      t.string :status, null: false, default: "pending_verification"
      t.timestamptz :phone_verified_at
      t.timestamptz :email_verified_at
      t.timestamptz :last_login_at
      t.integer :failed_login_attempts, null: false, default: 0
      t.timestamptz :locked_at
      t.timestamptz :disabled_at
      t.integer :lock_version, null: false, default: 0

      t.timestamps
    end

    add_index :users, :phone_number_digest, unique: true
    add_index :users, :email_digest, unique: true, where: "email_digest IS NOT NULL"
    add_index :users, :status

    add_check_constraint :users, "failed_login_attempts >= 0", name: "users_failed_login_attempts_non_negative"
  end
end
