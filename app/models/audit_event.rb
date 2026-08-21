# Append-only — never updated after creation. Always written through
# Audit::RecordEvent.
class AuditEvent < ApplicationRecord
  belongs_to :actor_user, class_name: "User", optional: true
  belongs_to :organization, optional: true
  belongs_to :branch, optional: true

  validates :actor_type, :action, :resource_type, :occurred_at, presence: true

  def readonly?
    persisted?
  end
end
