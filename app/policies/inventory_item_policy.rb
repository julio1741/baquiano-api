class InventoryItemPolicy < ApplicationPolicy
  def show? = manage?
  def create? = manage?
  def update? = manage?
  def destroy? = manage?

  private

  def manage?
    can_manage_branch?(record.branch, code: "availability:manage")
  end
end
