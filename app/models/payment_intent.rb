# status can only change through Payments::TransitionPaymentIntent, same
# guard pattern as Order/Delivery — direct writes are rejected.
class PaymentIntent < ApplicationRecord
  attr_accessor :status_change_authorized

  belongs_to :order
  belongs_to :customer
  has_many :payment_transactions, dependent: :restrict_with_error
  has_many :mobile_payment_submissions, dependent: :restrict_with_error
  has_many :pos_payment_records, dependent: :restrict_with_error
  has_many :refunds, dependent: :restrict_with_error

  enum :status, {
    created: "created",
    pending_customer_action: "pending_customer_action",
    pending_review: "pending_review",
    authorized: "authorized",
    captured: "captured",
    failed: "failed",
    cancelled: "cancelled",
    expired: "expired",
    partially_refunded: "partially_refunded",
    refunded: "refunded"
  }, validate: true, prefix: true

  enum :payment_method, { mobile_payment: "mobile_payment", pos_on_delivery: "pos_on_delivery", cash: "cash" },
       validate: true, prefix: true

  validates :idempotency_key, presence: true, uniqueness: { scope: :customer_id }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  before_update :prevent_direct_status_change

  def refunded_amount
    refunds.where(status: "completed").sum(:amount)
  end

  private

  def prevent_direct_status_change
    return unless will_save_change_to_status? && !status_change_authorized

    errors.add(:status, "cannot be changed directly — use Payments::TransitionPaymentIntent")
    throw :abort
  end
end
