class SupportCase < ApplicationRecord
  attr_accessor :status_change_authorized

  belongs_to :customer, optional: true
  belongs_to :order, optional: true
  belongs_to :delivery, optional: true
  belongs_to :opened_by_user, class_name: "User"
  belongs_to :assigned_to_user, class_name: "User", optional: true

  enum :status, {
    open: "open", in_progress: "in_progress", waiting_customer: "waiting_customer",
    waiting_merchant: "waiting_merchant", waiting_courier: "waiting_courier", resolved: "resolved",
    closed: "closed"
  }, validate: true

  enum :priority, { low: "low", medium: "medium", high: "high", urgent: "urgent" }, validate: true, prefix: true

  validates :public_number, presence: true, uniqueness: true
  validates :category, :subject, :description, :opened_at, presence: true

  before_update :prevent_direct_status_change

  private

  def prevent_direct_status_change
    return unless will_save_change_to_status? && !status_change_authorized

    errors.add(:status, "cannot be changed directly — use Support::TransitionCase")
    throw :abort
  end
end
