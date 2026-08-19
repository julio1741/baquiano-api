module Identity
  class RevokeSession
    def self.call(session:)
      session.revoke! unless session.revoked?
    end
  end
end
