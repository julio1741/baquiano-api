class Settlement < ApplicationRecord
  attr_accessor :status_change_authorized

  belongs_to :beneficiary, polymorphic: true
  belongs_to :approved_by_user, class_name: "User", optional: true
  encrypts :payment_reference_encrypted
  alias_attribute :payment_reference, :payment_reference_encrypted

  enum :status, { pending: "pending", approved: "approved", paid: "paid", failed: "failed" }, validate: true

  validates :period_start, :period_end, :currency, :idempotency_key, presence: true
  validates :idempotency_key, uniqueness: true
  validate :net_amount_matches_components

  before_update :prevent_direct_status_change

  private

  def net_amount_matches_components
    return if net_amount.to_i == gross_amount.to_i - commission_amount.to_i + adjustment_amount.to_i

    errors.add(:net_amount, "must equal gross_amount - commission_amount + adjustment_amount")
  end

  def prevent_direct_status_change
    return unless will_save_change_to_status? && !status_change_authorized

    errors.add(:status, "cannot be changed directly — use the Settlements services")
    throw :abort
  end
end
