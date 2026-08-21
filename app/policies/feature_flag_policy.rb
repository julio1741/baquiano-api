class FeatureFlagPolicy < ApplicationPolicy
  def index? = staff?
  def show? = staff?
  def create? = staff?
  def update? = staff?

  private

  def staff?
    has_permission?("organizations:manage") || has_permission?("settings:manage")
  end
end
