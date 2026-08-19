class OrganizationPolicy < ApplicationPolicy
  def index? = has_permission?("organizations:manage")
  def show? = has_permission?("organizations:manage")
  def create? = has_permission?("organizations:manage")
  def update? = has_permission?("organizations:manage")
  def destroy? = has_permission?("organizations:manage")
end
