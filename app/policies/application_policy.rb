class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index? = false
  def show? = false
  def create? = false
  def update? = false
  def destroy? = false

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NoMethodError, "You must define #resolve in #{self.class}"
    end
  end

  private

  def has_permission?(code, organization_id: nil, branch_id: nil)
    AccessControl::HasPermission.call(user: user, code: code, organization_id: organization_id, branch_id: branch_id)
  end
end
