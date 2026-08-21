# current_status can only change through Orders::TransitionOrder (section 5
# of the spec: "No permitir order.update!(current_status: ...)"). The model
# itself enforces this: any other code path trying to write current_status
# gets rejected — TransitionOrder authorizes itself via
# `status_change_authorized=` right before the one legitimate update.
class Order < ApplicationRecord
  attr_accessor :status_change_authorized

  belongs_to :customer
  belongs_to :organization
  belongs_to :merchant
  belongs_to :branch
  belongs_to :address
  belongs_to :quote
  belongs_to :exchange_rate, optional: true
  has_many :order_items, dependent: :restrict_with_error
  has_many :order_status_histories, dependent: :restrict_with_error
  has_many :order_transition_requests, dependent: :restrict_with_error
  has_one :delivery, dependent: :restrict_with_error
  has_one :payment_intent, dependent: :restrict_with_error
  has_many :refunds, dependent: :restrict_with_error
  has_many :support_cases, dependent: :restrict_with_error

  enum :current_status, {
    payment_pending: "payment_pending",
    payment_review: "payment_review",
    placed: "placed",
    merchant_pending: "merchant_pending",
    merchant_accepted: "merchant_accepted",
    merchant_rejected: "merchant_rejected",
    preparing: "preparing",
    ready_for_pickup: "ready_for_pickup",
    courier_search: "courier_search",
    courier_assigned: "courier_assigned",
    courier_at_merchant: "courier_at_merchant",
    picked_up: "picked_up",
    en_route: "en_route",
    courier_at_customer: "courier_at_customer",
    delivered: "delivered",
    cancellation_requested: "cancellation_requested",
    cancelled: "cancelled",
    delivery_failed: "delivery_failed",
    refund_pending: "refund_pending",
    partially_refunded: "partially_refunded",
    refunded: "refunded",
    disputed: "disputed",
    closed: "closed"
  }, validate: true, prefix: true

  enum :payment_status, { pending: "pending", not_required: "not_required", confirmed: "confirmed", refunded: "refunded" },
       validate: true, prefix: true

  enum :fulfillment_type, { delivery: "delivery", pickup: "pickup" }, validate: true
  enum :delivery_model, { baquiano: "baquiano", merchant: "merchant", hybrid: "hybrid" }, validate: true, prefix: true
  enum :payment_method, { mobile_payment: "mobile_payment", pos_on_delivery: "pos_on_delivery", cash: "cash" },
       validate: true, prefix: true

  validates :public_number, presence: true, uniqueness: true
  validates :idempotency_key, presence: true, uniqueness: { scope: :customer_id }
  validates :currency, presence: true
  validates :payment_method, presence: true
  validates :subtotal_amount, :total_amount, numericality: { greater_than_or_equal_to: 0 }

  validate :total_matches_components

  before_update :prevent_direct_status_change

  private

  def prevent_direct_status_change
    return unless will_save_change_to_current_status? && !status_change_authorized

    errors.add(:current_status, "cannot be changed directly — use Orders::TransitionOrder")
    throw :abort
  end

  def total_matches_components
    expected = subtotal_amount.to_i - discount_amount.to_i + tax_amount.to_i +
      delivery_fee_amount.to_i + service_fee_amount.to_i
    return if total_amount.to_i == expected

    errors.add(:total_amount, "must equal subtotal - discount + tax + delivery_fee + service_fee")
  end
end
