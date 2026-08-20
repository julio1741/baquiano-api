# status can only change through Payments::RequestRefund/ApproveRefund/
# CompleteRefund — same guard pattern as Order/Delivery/PaymentIntent.
class Refund < ApplicationRecord
  attr_accessor :status_change_authorized

  belongs_to :order
  belongs_to :payment_intent
  belongs_to :requested_by_user, class_name: "User"
  belongs_to :approved_by_user, class_name: "User", optional: true

  enum :status, { requested: "requested", approved: "approved", rejected: "rejected", completed: "completed",
                  failed: "failed" }, validate: true

  validates :reason_code, :idempotency_key, :requested_at, presence: true
  validates :idempotency_key, uniqueness: { scope: :order_id }
  validates :amount, numericality: { greater_than: 0 }

  before_update :prevent_direct_status_change

  private

  def prevent_direct_status_change
    return unless will_save_change_to_status? && !status_change_authorized

    errors.add(:status, "cannot be changed directly — use the Payments refund services")
    throw :abort
  end
end
