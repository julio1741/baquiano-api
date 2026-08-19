class ModifierGroupPolicy < ApplicationPolicy
  def show? = manage?
  def create? = manage?
  def update? = manage?
  def destroy? = manage?

  private

  def manage?
    can_manage_branch?(record.product.catalog.branch, code: "catalog:manage")
  end
end
