# Internal risk tooling — no self-service view; a subject never sees their
# own fraud signals/risk decisions.
class RiskDecisionPolicy < ApplicationPolicy
  def index? = staff?
  def show? = staff?
  def review? = staff?

  private

  def staff?
    has_permission?("organizations:manage") || has_permission?("risk:review")
  end
end
