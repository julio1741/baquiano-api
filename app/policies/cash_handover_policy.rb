class CashHandoverPolicy < ApplicationPolicy
  def show? = own_courier? || admin?
  def create? = own_courier?
  def confirm? = admin?

  private

  def own_courier?
    record.courier.present? && record.courier.user_id == user.id
  end

  def admin?
    has_permission?("organizations:manage")
  end
end
