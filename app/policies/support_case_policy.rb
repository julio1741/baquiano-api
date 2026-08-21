class SupportCasePolicy < ApplicationPolicy
  def index? = own? || staff?
  def show? = own? || staff?
  def create? = true
  def assign? = staff?
  def transition? = staff?

  private

  def own?
    return true if record.opened_by_user_id == user.id
    return true if record.customer.present? && record.customer.user_id == user.id
    return true if record.delivery&.courier.present? && record.delivery.courier.user_id == user.id

    false
  end

  def staff?
    has_permission?("organizations:manage") || has_permission?("support:manage")
  end
end
