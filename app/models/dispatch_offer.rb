class DispatchOffer < ApplicationRecord
  belongs_to :delivery
  belongs_to :courier

  enum :status, { pending: "pending", accepted: "accepted", rejected: "rejected", expired: "expired",
                  cancelled: "cancelled" }, validate: true

  validates :offered_at, :expires_at, presence: true

  def expired_and_still_pending?
    pending? && expires_at <= Time.current
  end
end
