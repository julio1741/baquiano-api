# Append-only signal log — never updated after creation.
class FraudSignal < ApplicationRecord
  belongs_to :order, optional: true
  belongs_to :payment_intent, optional: true
  belongs_to :subject, polymorphic: true

  enum :severity, { low: "low", medium: "medium", high: "high", critical: "critical" }, validate: true

  validates :signal_type, :score, :detected_at, presence: true

  def readonly?
    persisted?
  end
end
