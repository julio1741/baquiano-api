class SystemSettingPolicy < ApplicationPolicy
  def index? = staff?
  def show? = staff?
  def create? = staff?

  private

  def staff?
    has_permission?("organizations:manage") || has_permission?("settings:manage")
  end
end
