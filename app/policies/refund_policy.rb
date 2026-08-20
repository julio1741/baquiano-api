class RefundPolicy < ApplicationPolicy
  def show? = own_customer? || staff?
  def request? = own_customer? || staff?
  def decide? = has_permission?("organizations:manage") || has_permission?("refunds:create")

  private

  def own_customer?
    record.order&.customer.present? && record.order.customer.user_id == user.id
  end

  def staff?
    has_permission?("organizations:manage") ||
      has_permission?("payments:review", organization_id: record.order&.organization_id)
  end
end
