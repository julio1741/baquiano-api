class DispatchOfferPolicy < ApplicationPolicy
  def index? = own_offer?
  def show? = own_offer?
  def respond? = own_offer?

  private

  def own_offer?
    record.courier.present? && record.courier.user_id == user.id
  end
end
