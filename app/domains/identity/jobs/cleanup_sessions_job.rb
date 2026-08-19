module Identity
  # Retention hygiene for session records (section 8 of the spec): once a
  # session has been revoked or past its own expiry for a while, there's no
  # operational reason to keep it around. Idempotent — a plain DELETE.
  #
  # Not scheduled from application code (no cron gem in this MVP); wire it
  # up with whatever the deploy target offers.
  class CleanupSessionsJob < ApplicationJob
    queue_as :maintenance

    RETENTION = 90.days

    def perform
      Session.where(revoked_at: ...RETENTION.ago).or(Session.where(expires_at: ...RETENTION.ago)).delete_all
    end
  end
end
