class BranchPolicy < ApplicationPolicy
  def index? = has_permission?("organizations:manage")
  def show? = index? || can_manage_branch?(record, code: "branches:manage")
  def create? = has_permission?("organizations:manage")
  def update? = can_manage_branch?(record, code: "branches:manage")
  def destroy? = has_permission?("organizations:manage")
  def pause? = update?
  def resume? = update?
end
