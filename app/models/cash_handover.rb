class CashHandover < ApplicationRecord
  belongs_to :courier
  belongs_to :received_by_user, class_name: "User"

  enum :status, { pending: "pending", confirmed: "confirmed" }, validate: true

  validates :amount, numericality: { greater_than: 0 }
  validates :currency, :idempotency_key, :handed_over_at, presence: true
  validates :idempotency_key, uniqueness: { scope: :courier_id }
end
