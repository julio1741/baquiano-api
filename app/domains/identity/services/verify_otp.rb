module Identity
  # Verifies an OTP and, on success, resolves the account (creating it on
  # first verification — there is no separate "register" endpoint) and
  # issues a session. first_name/last_name are only required the first time
  # a phone number is seen; an existing account ignores them.
  class VerifyOtp
    Result = Struct.new(:user, :device, :session, :access_token, :access_token_expires_at, :refresh_token, keyword_init: true)

    def self.call(...) = new(...).call

    def initialize(country_code:, phone_number:, code:, purpose:, device_attrs:, ip: nil, user_agent: nil,
                   first_name: nil, last_name: nil)
      @country_code = country_code
      @phone_number = phone_number
      @code = code
      @purpose = purpose.to_s
      @device_attrs = device_attrs
      @ip = ip
      @user_agent = user_agent
      @first_name = first_name
      @last_name = last_name
    end

    def call
      challenge = latest_challenge
      check_challenge!(challenge)

      unless challenge.matches_code?(@code)
        challenge.register_attempt!
        raise ValidationError.new("incorrect code", code: "otp_incorrect")
      end

      ActiveRecord::Base.transaction do
        challenge.consume!
        user = resolve_user!
        mark_verified!(user)

        device = Identity::RegisterDevice.call(user: user, **@device_attrs)
        raise ForbiddenError.new("device blocked", code: "device_blocked") if device.blocked?

        issued = Identity::IssueSession.call(user: user, device: device, ip: @ip, user_agent: @user_agent)

        Result.new(
          user: user, device: device, session: issued.session, access_token: issued.access_token,
          access_token_expires_at: issued.access_token_expires_at, refresh_token: issued.refresh_token
        )
      end
    end

    private

    def latest_challenge
      phone_digest = BlindIndex.digest(Phone.e164(@country_code, @phone_number))
      OtpChallenge.where(phone_digest: phone_digest, purpose: @purpose).order(created_at: :desc).first
    end

    def check_challenge!(challenge)
      raise NotFoundError.new("otp not found", code: "otp_not_found") unless challenge
      raise ConflictError.new("otp already used", code: "otp_already_used") if challenge.consumed?
      raise ConflictError.new("otp expired", code: "otp_expired") if challenge.expired?
      raise ConflictError.new("otp attempts exhausted", code: "otp_attempts_exhausted") if challenge.exhausted?
    end

    def resolve_user!
      User.find_by_phone(@country_code, @phone_number) || create_user!
    end

    def create_user!
      if @first_name.blank? || @last_name.blank?
        raise ValidationError.new("first_name and last_name are required to sign up", code: "profile_required")
      end

      User.create!(
        phone_country_code: @country_code, phone_number: @phone_number,
        first_name: @first_name, last_name: @last_name
      )
    end

    def mark_verified!(user)
      raise ForbiddenError.new("account disabled", code: "account_disabled") if user.disabled_at.present?
      raise ForbiddenError.new("account locked", code: "account_locked") if user.locked_at.present?

      user.phone_verified_at ||= Time.current
      user.status = "active" if user.pending_verification?
      user.failed_login_attempts = 0
      user.last_login_at = Time.current
      user.save!
    end
  end
end
