class CashBalancePolicy < ApplicationPolicy
  def show? = own_courier? || admin?
  # Admin-only, no own_courier? fallback — setting exposure_limit/
  # blocked_for_cash_orders on yourself would be a self-escalation
  # (same trap as CourierPolicy#manage? — Authenticatable doesn't gate
  # routes by token app_type, see docs/architecture/decisions.md).
  def manage? = admin?

  private

  def own_courier?
    record.courier.present? && record.courier.user_id == user.id
  end

  def admin?
    has_permission?("organizations:manage")
  end
end
