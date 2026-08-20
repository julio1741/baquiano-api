class SettlementPolicy < ApplicationPolicy
  def show? = own_beneficiary? || admin?
  def create? = admin?
  def approve? = admin?
  def mark_paid? = admin?

  private

  def own_beneficiary?
    case record.beneficiary
    when ::Courier
      record.beneficiary.user_id == user.id
    when ::Merchant
      has_permission?("organizations:manage") ||
        has_permission?("orders:read", organization_id: record.beneficiary.organization_id)
    else
      false
    end
  end

  def admin?
    has_permission?("organizations:manage")
  end
end
