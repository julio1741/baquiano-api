# status can only change through Deliveries::TransitionDelivery, same
# pattern as Order (see app/models/order.rb) — direct writes are rejected.
#
# delivery_pin is stored both encrypted (so the customer can be shown it
# again on their tracking screen — section 4.14 only lists a digest column,
# but a PIN the customer can only ever see once isn't workable in practice)
# and as a digest (what #matches_pin? actually compares against, avoiding a
# decrypt on every courier PIN-entry attempt). See
# docs/architecture/decisions.md.
class Delivery < ApplicationRecord
  attr_accessor :status_change_authorized

  encrypts :delivery_pin_encrypted
  alias_attribute :delivery_pin, :delivery_pin_encrypted

  belongs_to :order
  belongs_to :courier, optional: true
  belongs_to :branch
  has_many :dispatch_offers, dependent: :restrict_with_error
  has_many :location_pings, dependent: :nullify
  has_many :delivery_incidents, dependent: :restrict_with_error
  has_many :support_cases, dependent: :restrict_with_error

  enum :status, {
    pending_assignment: "pending_assignment",
    offered: "offered",
    assigned: "assigned",
    accepted: "accepted",
    at_merchant: "at_merchant",
    picked_up: "picked_up",
    en_route: "en_route",
    at_customer: "at_customer",
    delivered: "delivered",
    failed: "failed",
    cancelled: "cancelled"
  }, validate: true, prefix: true

  enum :delivery_model, { baquiano: "baquiano", merchant: "merchant", hybrid: "hybrid" }, validate: true, prefix: true

  validates :pickup_location, :dropoff_location, presence: true

  before_update :prevent_direct_status_change
  before_validation :set_delivery_pin_digest

  def matches_pin?(pin)
    return false if pin.blank? || delivery_pin_digest.blank?

    ActiveSupport::SecurityUtils.secure_compare(delivery_pin_digest, BlindIndex.digest(pin))
  end

  private

  def prevent_direct_status_change
    return unless will_save_change_to_status? && !status_change_authorized

    errors.add(:status, "cannot be changed directly — use Deliveries::TransitionDelivery")
    throw :abort
  end

  def set_delivery_pin_digest
    return unless will_save_change_to_delivery_pin_encrypted?

    self.delivery_pin_digest = BlindIndex.digest(delivery_pin)
  end
end
