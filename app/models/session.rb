class Session < ApplicationRecord
  belongs_to :user
  belongs_to :device
  belongs_to :rotated_from_session, class_name: "Session", optional: true
  has_one :rotated_to_session, class_name: "Session", foreign_key: :rotated_from_session_id, inverse_of: :rotated_from_session

  validates :refresh_token_digest, presence: true, uniqueness: true
  validates :expires_at, presence: true

  def revoked?
    revoked_at.present?
  end

  def expired?
    expires_at <= Time.current
  end

  def active?
    !revoked? && !expired?
  end

  def revoke!
    update!(revoked_at: Time.current)
  end
end
