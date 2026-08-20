class DeliveryPolicy < ApplicationPolicy
  def show? = own_delivery? || staff?
  def update_status? = own_delivery?

  def assign?
    has_permission?("organizations:manage") ||
      has_permission?("deliveries:assign", organization_id: record.order&.organization_id, branch_id: record.branch_id)
  end

  private

  def own_delivery?
    record.courier.present? && record.courier.user_id == user.id
  end

  def staff?
    has_permission?("organizations:manage") ||
      has_permission?("orders:read", organization_id: record.order&.organization_id, branch_id: record.branch_id)
  end
end
