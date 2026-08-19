class PermissionPolicy < ApplicationPolicy
  def index? = has_permission?("users:manage_roles")
  def show? = has_permission?("users:manage_roles")
end
