class ModifierPolicy < ApplicationPolicy
  def show? = manage?
  def create? = manage?
  def update? = manage?
  def destroy? = manage?

  private

  def manage?
    can_manage_branch?(record.modifier_group.product.catalog.branch, code: "catalog:manage")
  end
end
