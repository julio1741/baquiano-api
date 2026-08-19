class RoleAssignmentPolicy < ApplicationPolicy
  def create?
    has_permission?("users:manage_roles", organization_id: record.organization_id, branch_id: record.branch_id)
  end

  def destroy?
    has_permission?("users:manage_roles", organization_id: record.organization_id, branch_id: record.branch_id)
  end
end
