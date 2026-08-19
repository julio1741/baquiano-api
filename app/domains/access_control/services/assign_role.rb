module AccessControl
  class AssignRole
    def self.call(...) = new(...).call

    def initialize(user:, role:, assigned_by:, organization_id: nil, branch_id: nil, starts_at: Time.current, expires_at: nil)
      @user = user
      @role = role
      @assigned_by = assigned_by
      @organization_id = organization_id
      @branch_id = branch_id
      @starts_at = starts_at
      @expires_at = expires_at
    end

    def call
      RoleAssignment.create!(
        user: @user,
        role: @role,
        assigned_by_user: @assigned_by,
        organization_id: @organization_id,
        branch_id: @branch_id,
        starts_at: @starts_at,
        expires_at: @expires_at
      )
    end
  end
end
