module Identity
  # No SMS gateway is wired up yet for Barinas/Venezuela — that's a
  # commercial/technical decision this MVP hasn't made (see
  # docs/architecture/decisions.md). Until then this only logs that a
  # dispatch was requested; the plaintext code is never logged outside
  # local development, and is never persisted (only code_digest is).
  class DeliverOtpJob < ApplicationJob
    queue_as :notifications

    def perform(otp_challenge_id, code)
      challenge = OtpChallenge.find_by(id: otp_challenge_id)
      return unless challenge&.usable?

      Rails.logger.info(event: "otp_dispatch_requested", otp_challenge_id: otp_challenge_id, purpose: challenge.purpose)
      Rails.logger.debug { "[dev-only] OTP code for challenge #{otp_challenge_id}: #{code}" } if Rails.env.local?
    end
  end
end
