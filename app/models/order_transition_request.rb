# Idempotency ledger for user-initiated transition requests (a merchant
# clicking "accept" twice, a flaky retry, ...). System-initiated automatic
# transitions (e.g. placed -> merchant_pending right after PlaceOrder) don't
# go through this — there's no requesting user to key off of.
class OrderTransitionRequest < ApplicationRecord
  belongs_to :order
  belongs_to :requested_by_user, class_name: "User"

  enum :status, { pending: "pending", succeeded: "succeeded", failed: "failed" }, validate: true

  validates :requested_transition, :idempotency_key, presence: true
  validates :idempotency_key, uniqueness: { scope: :order_id }
end
