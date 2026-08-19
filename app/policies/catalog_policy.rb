class CatalogPolicy < ApplicationPolicy
  def show? = manage?
  def create? = manage?
  def update? = manage?
  def destroy? = manage?
  def publish? = manage?

  private

  def manage?
    can_manage_branch?(record.branch, code: "catalog:manage")
  end
end
