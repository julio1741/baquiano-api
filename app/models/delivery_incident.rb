class DeliveryIncident < ApplicationRecord
  belongs_to :delivery
  belongs_to :order
  belongs_to :reported_by_user, class_name: "User"
  belongs_to :resolved_by_user, class_name: "User", optional: true

  enum :status, { open: "open", investigating: "investigating", resolved: "resolved", dismissed: "dismissed" },
       validate: true

  validates :incident_type, :severity, :description, :occurred_at, presence: true

  def resolve!(resolved_by:, resolution:)
    update!(status: "resolved", resolution: resolution, resolved_by_user: resolved_by, resolved_at: Time.current)
  end
end
