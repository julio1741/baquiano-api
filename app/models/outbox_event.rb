# The work queue side of the transactional outbox pattern: written in the
# same transaction as its matching DomainEvent, then picked up later by a
# publisher job and marked published/failed. Unlike DomainEvent, this one
# does get updated (as it moves through pending -> published/failed).
class OutboxEvent < ApplicationRecord
  enum :status, { pending: "pending", published: "published", failed: "failed" }, validate: true

  validates :event_type, :aggregate_type, presence: true
  validates :aggregate_id, :available_at, presence: true

  def publish!
    update!(status: "published", published_at: Time.current)
  end

  def register_failure!(message)
    update!(status: "failed", attempt_count: attempt_count + 1, last_error: message)
  end
end
