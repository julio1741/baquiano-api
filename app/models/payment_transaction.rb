# Append-only record of what actually happened against a PaymentIntent —
# never updated after creation, same pattern as DomainEvent/OrderItem.
class PaymentTransaction < ApplicationRecord
  encrypts :raw_response_encrypted

  belongs_to :payment_intent

  enum :transaction_type, {
    authorization: "authorization", capture: "capture", payment: "payment", void: "void", refund: "refund",
    chargeback: "chargeback", adjustment: "adjustment"
  }, validate: true

  validates :status, :idempotency_key, :occurred_at, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :idempotency_key, uniqueness: { scope: :payment_intent_id }

  def readonly?
    persisted?
  end
end
