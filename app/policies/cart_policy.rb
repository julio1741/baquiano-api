class CartPolicy < ApplicationPolicy
  def show? = own_record?
  def create? = own_record?
  def update? = own_record?

  private

  def own_record?
    record.customer.user_id == user.id
  end
end
