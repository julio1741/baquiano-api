class ReconciliationBatchPolicy < ApplicationPolicy
  def index? = admin?
  def show? = admin?
  def create? = admin?
  def resolve_item? = admin?
  def complete? = admin?

  private

  def admin?
    has_permission?("organizations:manage")
  end
end
