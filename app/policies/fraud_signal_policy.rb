class FraudSignalPolicy < ApplicationPolicy
  def index? = staff?
  def show? = staff?

  private

  def staff?
    has_permission?("organizations:manage") || has_permission?("risk:review")
  end
end
