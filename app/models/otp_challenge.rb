class OtpChallenge < ApplicationRecord
  enum :purpose, {
    sign_in: "sign_in",
    verify_phone: "verify_phone",
    sensitive_action: "sensitive_action",
    account_recovery: "account_recovery"
  }, validate: true

  validates :phone_digest, :code_digest, presence: true
  validates :expires_at, presence: true

  def self.generate_code
    SecureRandom.random_number(1_000_000).to_s.rjust(6, "0")
  end

  def consumed?
    consumed_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def exhausted?
    attempt_count >= maximum_attempts
  end

  def usable?
    !consumed? && !expired? && !exhausted?
  end

  def register_attempt!
    increment!(:attempt_count)
  end

  def consume!
    update!(consumed_at: Time.current)
  end

  def matches_code?(code)
    return false if code.blank?

    ActiveSupport::SecurityUtils.secure_compare(code_digest, BlindIndex.digest(code))
  end
end
