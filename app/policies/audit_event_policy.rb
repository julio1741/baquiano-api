class AuditEventPolicy < ApplicationPolicy
  def index? = staff?
  def show? = staff?

  private

  def staff?
    has_permission?("organizations:manage") || has_permission?("audit:read")
  end
end
