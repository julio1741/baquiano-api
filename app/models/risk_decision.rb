class RiskDecision < ApplicationRecord
  belongs_to :order, optional: true
  belongs_to :subject, polymorphic: true
  belongs_to :reviewed_by_user, class_name: "User", optional: true

  # prefix: true — "reject" would otherwise collide with
  # ActiveRecord::Relation's own Enumerable#reject.
  enum :decision, {
    allow: "allow", challenge: "challenge", hold: "hold", manual_review: "manual_review",
    restrict_payment_method: "restrict_payment_method", reject: "reject", suspend: "suspend"
  }, validate: true, prefix: true

  validates :risk_score, :rules_version, presence: true

  def review!(reviewed_by:)
    update!(reviewed_by_user: reviewed_by, reviewed_at: Time.current)
  end
end
