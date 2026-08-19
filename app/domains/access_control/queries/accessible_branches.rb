module AccessControl
  # Branches a user can act on as merchant staff, via any active role
  # assignment scoped to their organization (org-wide) or directly to a
  # branch — regardless of which specific permission the role grants; the
  # per-action Pundit policy still enforces the actual permission needed.
  class AccessibleBranches
    def self.call(user:)
      organization_ids = user.role_assignments.where(revoked_at: nil).where(branch_id: nil)
        .where.not(organization_id: nil).select(:organization_id)
      branch_ids = user.role_assignments.where(revoked_at: nil).where.not(branch_id: nil).select(:branch_id)

      Branch.where(organization_id: organization_ids).or(Branch.where(id: branch_ids))
    end
  end
end
