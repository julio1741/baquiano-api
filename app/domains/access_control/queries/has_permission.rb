module AccessControl
  # The single place that answers "can this user do X [in this org/branch]?".
  # Every Pundit policy in the app should route through this rather than
  # querying role_assignments directly, so the scope-matching rules stay in
  # one place. Deny by default: an unrecognized user/nil short-circuits to
  # false instead of raising.
  class HasPermission
    def self.call(user:, code:, organization_id: nil, branch_id: nil)
      return false if user.nil?

      RoleAssignment
        .joins(role: :permissions)
        .where(user: user, permissions: { code: code })
        .where(revoked_at: nil)
        .where("starts_at <= ?", Time.current)
        .where("expires_at IS NULL OR expires_at > ?", Time.current)
        .where(scope_conditions(organization_id, branch_id))
        .exists?
    end

    # A platform-scoped assignment (no organization/branch) always applies.
    # An organization-scoped assignment applies anywhere within that
    # organization. A branch-scoped assignment applies only to that branch.
    def self.scope_conditions(organization_id, branch_id)
      global = "(role_assignments.organization_id IS NULL AND role_assignments.branch_id IS NULL)"

      if branch_id
        [
          "#{global} OR (role_assignments.organization_id = ? AND role_assignments.branch_id IS NULL) OR role_assignments.branch_id = ?",
          organization_id, branch_id
        ]
      elsif organization_id
        [ "#{global} OR (role_assignments.organization_id = ? AND role_assignments.branch_id IS NULL)", organization_id ]
      else
        [ global ]
      end
    end
  end
end
