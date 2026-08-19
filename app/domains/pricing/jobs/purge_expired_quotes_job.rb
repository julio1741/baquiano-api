module Pricing
  # Section 8 of the spec: "Expiración de cotizaciones". Quotes have no
  # status column (only expires_at/consumed_at — see Quote#expired?), so
  # there's no state to flip; this is retention hygiene, purging old
  # consumed-or-expired quotes outright, same pattern as
  # Identity::PurgeExpiredOtpChallengesJob.
  class PurgeExpiredQuotesJob < ApplicationJob
    queue_as :maintenance

    RETENTION = 7.days

    def perform
      Quote.where(expires_at: ...RETENTION.ago).delete_all
    end
  end
end
