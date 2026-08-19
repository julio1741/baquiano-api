class UserPolicy < ApplicationPolicy
  def show?
    own_record? || has_permission?("users:manage_roles")
  end

  def update?
    own_record?
  end

  private

  def own_record?
    user == record
  end
end
