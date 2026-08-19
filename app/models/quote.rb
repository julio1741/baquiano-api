# Immutable once created — totals are computed once by Pricing::GenerateQuote
# and never recalculated (a stale quote just expires; see section 4.7:
# "El cliente nunca enviará un total final confiable").
class Quote < ApplicationRecord
  belongs_to :cart
  belongs_to :customer
  belongs_to :branch
  belongs_to :address
  belongs_to :exchange_rate, optional: true

  validates :currency, presence: true, format: { with: /\A[A-Z]{3}\z/ }
  validates :subtotal_amount, :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :idempotency_key, presence: true, uniqueness: { scope: :customer_id }
  validates :expires_at, presence: true

  validate :total_matches_components

  def expired?
    expires_at <= Time.current
  end

  def consumed?
    consumed_at.present?
  end

  def consume!
    update!(consumed_at: Time.current)
  end

  private

  def total_matches_components
    expected = subtotal_amount.to_i - discount_amount.to_i + tax_amount.to_i +
      delivery_fee_amount.to_i + service_fee_amount.to_i
    return if total_amount.to_i == expected

    errors.add(:total_amount, "must equal subtotal - discount + tax + delivery_fee + service_fee")
  end
end
