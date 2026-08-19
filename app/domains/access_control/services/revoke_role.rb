module AccessControl
  class RevokeRole
    def self.call(role_assignment:, revoked_by:, reason: nil)
      role_assignment.revoke!(by: revoked_by, reason: reason)
    end
  end
end
