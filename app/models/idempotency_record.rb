class IdempotencyRecord < ApplicationRecord
  encrypts :response_body_encrypted

  validates :key, :actor_type, :actor_id, :operation, :request_digest, :expires_at, presence: true
  validates :key, uniqueness: { scope: %i[actor_type actor_id operation] }

  def expired?
    expires_at <= Time.current
  end
end
