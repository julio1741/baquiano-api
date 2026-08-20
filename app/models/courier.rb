class Courier < ApplicationRecord
  belongs_to :user
  belongs_to :organization, optional: true
  has_many :vehicles, dependent: :destroy
  has_many :courier_documents, dependent: :destroy
  has_many :courier_availabilities, dependent: :destroy
  has_many :courier_branch_assignments, dependent: :destroy
  has_many :deliveries, dependent: :restrict_with_error
  has_many :dispatch_offers, dependent: :restrict_with_error
  has_many :location_pings, dependent: :destroy

  enum :courier_type, { baquiano: "baquiano", merchant: "merchant" }, validate: true, prefix: true
  enum :status, { pending: "pending", active: "active", suspended: "suspended" }, validate: true
  enum :approval_status, { pending: "pending", approved: "approved", rejected: "rejected" }, validate: true,
                          prefix: true

  validates :risk_level, presence: true

  def active_vehicle
    vehicles.find_by(active: true)
  end

  def open_availability
    courier_availabilities.find_by(ended_at: nil)
  end

  def approve!
    update!(approval_status: "approved", status: "active", approved_at: Time.current)
  end

  def reject!(reason:)
    update!(approval_status: "rejected", suspension_reason: reason)
  end

  def suspend!(reason:)
    update!(status: "suspended", suspended_at: Time.current, suspension_reason: reason)
  end
end
