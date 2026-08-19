class CreateOtpChallenges < ActiveRecord::Migration[8.1]
  def change
    create_table :otp_challenges, id: :uuid do |t|
      t.string :phone_digest, null: false
      t.string :purpose, null: false
      t.string :code_digest, null: false
      t.timestamptz :expires_at, null: false
      t.timestamptz :consumed_at
      t.integer :attempt_count, null: false, default: 0
      t.integer :maximum_attempts, null: false, default: 5
      t.inet :requested_ip
      t.string :device_fingerprint_digest

      t.timestamps
    end

    add_index :otp_challenges, [ :phone_digest, :purpose, :created_at ]

    add_check_constraint :otp_challenges, "attempt_count >= 0", name: "otp_challenges_attempt_count_non_negative"
    add_check_constraint :otp_challenges, "maximum_attempts > 0", name: "otp_challenges_maximum_attempts_positive"
  end
end
