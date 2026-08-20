class ReconciliationItem < ApplicationRecord
  belongs_to :reconciliation_batch
  belongs_to :payment_transaction, optional: true
  belongs_to :resolved_by_user, class_name: "User", optional: true

  enum :status, { pending: "pending", matched: "matched", discrepant: "discrepant", resolved: "resolved" },
       validate: true

  validates :expected_amount, :actual_amount, :currency, presence: true

  before_validation :set_difference_amount
  before_validation :set_status

  def resolve!(resolved_by:, resolution_code:, resolution_notes: nil)
    update!(status: "resolved", resolved_by_user: resolved_by, resolved_at: Time.current,
            resolution_code: resolution_code, resolution_notes: resolution_notes)
  end

  private

  def set_difference_amount
    self.difference_amount = actual_amount.to_i - expected_amount.to_i
  end

  def set_status
    return if resolved? || status == "resolved"

    self.status = difference_amount.zero? ? "matched" : "discrepant"
  end
end
