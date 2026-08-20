class PaymentIntentPolicy < ApplicationPolicy
  def show? = own_customer? || staff?
  def submit_mobile_payment? = own_customer?
  def review? = staff?

  private

  def own_customer?
    record.order&.customer.present? && record.order.customer.user_id == user.id
  end

  def staff?
    has_permission?("organizations:manage") ||
      has_permission?("payments:review", organization_id: record.order&.organization_id)
  end
end
