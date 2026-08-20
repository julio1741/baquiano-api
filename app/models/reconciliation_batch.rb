class ReconciliationBatch < ApplicationRecord
  belongs_to :started_by_user, class_name: "User"
  belongs_to :completed_by_user, class_name: "User", optional: true
  has_many :reconciliation_items, dependent: :restrict_with_error

  enum :status, { open: "open", completed: "completed" }, validate: true

  validates :provider, :payment_method, :currency, :period_start, :period_end, :started_at, presence: true

  def recompute_totals!
    update!(
      expected_amount: reconciliation_items.sum(:expected_amount),
      actual_amount: reconciliation_items.sum(:actual_amount),
      difference_amount: reconciliation_items.sum(:actual_amount) - reconciliation_items.sum(:expected_amount)
    )
  end
end
