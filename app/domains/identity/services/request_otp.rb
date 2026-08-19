module Identity
  # Issues a new OTP challenge for a phone number. Anti-enumeration: the
  # response is identical whether or not the phone belongs to an existing
  # user — VerifyOtp resolves (or creates) the user only once the code is
  # confirmed.
  class RequestOtp
    RESEND_INTERVAL = 60.seconds
    EXPIRY = 5.minutes

    Result = Struct.new(:otp_challenge, :dev_only_code, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(country_code:, phone_number:, purpose:, ip: nil, device_fingerprint: nil)
      @country_code = country_code
      @phone_number = phone_number
      @purpose = purpose.to_s
      @ip = ip
      @device_fingerprint = device_fingerprint
    end

    def call
      e164 = Phone.e164(@country_code, @phone_number)
      raise ValidationError.new("invalid phone number", code: "invalid_phone") if e164.blank?

      phone_digest = BlindIndex.digest(e164)
      enforce_resend_interval!(phone_digest)

      code = OtpChallenge.generate_code
      challenge = OtpChallenge.create!(
        phone_digest: phone_digest,
        purpose: @purpose,
        code_digest: BlindIndex.digest(code),
        expires_at: EXPIRY.from_now,
        requested_ip: @ip,
        device_fingerprint_digest: @device_fingerprint.presence && BlindIndex.digest(@device_fingerprint)
      )

      Identity::DeliverOtpJob.perform_later(challenge.id, code)

      Result.new(otp_challenge: challenge, dev_only_code: (code if Rails.env.local?))
    end

    private

    def enforce_resend_interval!(phone_digest)
      last = OtpChallenge.where(phone_digest: phone_digest, purpose: @purpose).order(created_at: :desc).first
      return unless last && last.created_at > RESEND_INTERVAL.ago

      raise ConflictError.new("an otp was already sent recently", code: "otp_recently_sent")
    end
  end
end
