module Deliveries
  # Resolves the retention gap flagged since Increment 5 (section 4.14:
  # "Política de retención"). Plain deletion past the window, same
  # approach as Identity::CleanupSessionsJob — no precision-reduction
  # intermediate representation exists, and full-precision pings have no
  # operational value once a delivery is long since finished.
  class PurgeOldLocationPingsJob < ApplicationJob
    queue_as :maintenance

    RETENTION = 90.days

    def perform
      LocationPing.where(server_received_at: ...RETENTION.ago).delete_all
    end
  end
end
