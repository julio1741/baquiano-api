module Identity
  # Rotates the refresh token on every use. If a token that was already
  # rotated away gets presented again, that's a signal it leaked — the
  # entire chain descending from it is revoked defensively (reuse detection).
  class RefreshSession
    def self.call(...) = new(...).call

    def initialize(refresh_token:, ip: nil, user_agent: nil)
      @refresh_token = refresh_token
      @ip = ip
      @user_agent = user_agent
    end

    def call
      session = Session.find_by(refresh_token_digest: BlindIndex.digest(@refresh_token))
      raise NotFoundError.new("session not found", code: "invalid_refresh_token") unless session

      if session.revoked?
        revoke_chain!(session)
        raise ForbiddenError.new("refresh token reuse detected", code: "refresh_token_reused")
      end
      raise ForbiddenError.new("session expired", code: "session_expired") if session.expired?
      raise ForbiddenError.new("device blocked", code: "device_blocked") if session.device.blocked?

      ActiveRecord::Base.transaction do
        session.lock!
        session.revoke!
        Identity::IssueSession.call(
          user: session.user, device: session.device, ip: @ip, user_agent: @user_agent, rotated_from: session
        )
      end
    end

    private

    def revoke_chain!(session)
      node = session
      while node
        node.update!(revoked_at: Time.current) unless node.revoked?
        node = node.rotated_to_session
      end
    end
  end
end
