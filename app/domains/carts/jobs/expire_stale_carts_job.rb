module Carts
  # Section 8 of the spec: "Expiración de carritos". Flips carts whose TTL
  # has passed but are still marked "active" (Carts::GetOrCreateActiveCart
  # already handles this lazily on next access; this job catches carts that
  # are never revisited). Idempotent — re-running only touches rows still
  # "active" past their expiry.
  #
  # Not scheduled from application code (no cron gem in this MVP); wire it
  # up with whatever the deploy target offers.
  class ExpireStaleCartsJob < ApplicationJob
    queue_as :maintenance

    def perform
      Cart.where(status: "active").where(expires_at: ...Time.current).find_each do |cart|
        cart.update!(status: "expired")
      end
    end
  end
end
