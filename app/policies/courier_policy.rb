class CourierPolicy < ApplicationPolicy
  def index? = has_permission?("organizations:manage")
  def show? = own_courier? || has_permission?("organizations:manage")
  def create? = own_courier?
  # Self-service: the courier editing their own low-stakes profile fields
  # (Api::V1::Courier::CouriersController — courier_type only, never
  # risk_level/cash_enabled/organization_id).
  def update? = own_courier?
  # Admin-only: no own_courier? fallback here on purpose — admin's own
  # controller permits broader fields (cash_enabled, maximum_cash_exposure,
  # organization_id) that a courier must never be able to set on
  # themselves, and Authenticatable doesn't gate routes by token app_type
  # (see docs/architecture/decisions.md), so this can't rely on "a courier
  # token would never reach the admin controller" being true.
  def manage? = has_permission?("organizations:manage")
  def approve? = has_permission?("organizations:manage")
  def reject? = has_permission?("organizations:manage")
  def suspend? = has_permission?("organizations:manage")

  private

  def own_courier?
    record.user_id == user.id
  end
end
