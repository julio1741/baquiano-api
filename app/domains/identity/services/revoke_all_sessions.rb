module Identity
  # Used for "cerrar sesión en todos los dispositivos" and for account
  # security actions (e.g. after a sensitive change) that must invalidate
  # every existing session at once.
  class RevokeAllSessions
    def self.call(user:)
      user.sessions.where(revoked_at: nil).find_each(&:revoke!)
    end
  end
end
