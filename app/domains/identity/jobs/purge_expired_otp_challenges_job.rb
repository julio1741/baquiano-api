module Identity
  # Retention hygiene: OTP challenges only need to exist long enough to be
  # consumed or expire. Nothing depends on keeping them past that, so old
  # ones (even the hashed code) are purged outright rather than archived.
  # Idempotent — a plain DELETE, safe to run repeatedly or concurrently.
  #
  # Not scheduled from application code (no cron gem in this MVP); wire it
  # up with whatever the deploy target offers (Sidekiq-cron, systemd timer,
  # platform scheduler, ...).
  class PurgeExpiredOtpChallengesJob < ApplicationJob
    queue_as :maintenance

    RETENTION = 1.day

    def perform
      OtpChallenge.where(expires_at: ...RETENTION.ago).delete_all
    end
  end
end
