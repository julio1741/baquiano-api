class MobilePaymentSubmission < ApplicationRecord
  belongs_to :payment_intent
  belongs_to :reviewed_by_user, class_name: "User", optional: true
  belongs_to :duplicate_of_submission, class_name: "MobilePaymentSubmission", optional: true

  enum :review_status, {
    submitted: "submitted", under_review: "under_review", confirmed: "confirmed", rejected: "rejected",
    duplicate: "duplicate"
  }, validate: true

  validates :reference, :paid_at, presence: true
  validates :amount, numericality: { greater_than_or_equal_to: 0 }

  before_validation :set_reference_digest

  private

  def set_reference_digest
    self.reference_digest = BlindIndex.digest(reference)
  end
end
