class RolePolicy < ApplicationPolicy
  def index? = has_permission?("users:manage_roles")
  def show? = has_permission?("users:manage_roles")
  def create? = has_permission?("users:manage_roles")
  def update? = has_permission?("users:manage_roles")
  def destroy? = has_permission?("users:manage_roles")
end
