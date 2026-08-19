module Identity
  # Access tokens are short-lived signed messages (Rails' own MessageVerifier
  # — no extra JWT dependency needed), never persisted. Refresh tokens are
  # opaque random strings; only their digest is stored, so a stolen database
  # doesn't hand out working sessions.
  class IssueSession
    ACCESS_TOKEN_TTL = 15.minutes
    REFRESH_TOKEN_TTL = 30.days

    Result = Struct.new(:session, :access_token, :access_token_expires_at, :refresh_token, keyword_init: true)

    def self.call(...) = new(...).call

    def self.access_token_verifier
      Rails.application.message_verifier(:api_access_token)
    end

    def self.decode_access_token(token)
      access_token_verifier.verify(token)
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      nil
    end

    def initialize(user:, device:, ip: nil, user_agent: nil, rotated_from: nil)
      @user = user
      @device = device
      @ip = ip
      @user_agent = user_agent
      @rotated_from = rotated_from
    end

    def call
      refresh_token = SecureRandom.urlsafe_base64(32)
      session = Session.create!(
        user: @user,
        device: @device,
        refresh_token_digest: BlindIndex.digest(refresh_token),
        ip_address: @ip,
        user_agent: @user_agent,
        expires_at: REFRESH_TOKEN_TTL.from_now,
        last_used_at: Time.current,
        rotated_from_session: @rotated_from
      )

      expires_at = ACCESS_TOKEN_TTL.from_now
      access_token = self.class.access_token_verifier.generate(
        { session_id: session.id, user_id: @user.id }, expires_at: expires_at
      )

      Result.new(session: session, access_token: access_token, access_token_expires_at: expires_at, refresh_token: refresh_token)
    end
  end
end
