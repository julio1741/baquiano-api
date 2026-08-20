# The permanent, append-only record of what happened (section 9 of the
# spec). Never updated or deleted once written — write through
# Events::Publish, not directly.
class DomainEvent < ApplicationRecord
  validates :aggregate_type, :event_type, presence: true
  validates :aggregate_id, :occurred_at, :correlation_id, presence: true

  def readonly?
    persisted?
  end
end
