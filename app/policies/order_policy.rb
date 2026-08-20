class OrderPolicy < ApplicationPolicy
  def index? = own_customer? || staff?
  def show? = own_customer? || staff?
  def cancel? = own_customer?
  def update_status? = staff?

  private

  def own_customer?
    record.customer.present? && record.customer.user_id == user.id
  end

  def staff?
    has_permission?("organizations:manage") ||
      has_permission?("orders:update_status", organization_id: record.organization_id, branch_id: record.branch_id)
  end
end
