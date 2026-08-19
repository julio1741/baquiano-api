module Carts
  # One active cart per (customer, branch) — enforced by a DB partial unique
  # index, not just this service. If the existing one has passed its own
  # expires_at but a cleanup job hasn't marked it "expired" yet, retire it
  # and start a fresh one rather than resurrecting stale line items.
  class GetOrCreateActiveCart
    TTL = 2.hours

    def self.call(customer:, branch:)
      ActiveRecord::Base.transaction do
        cart = Cart.lock.find_by(customer: customer, branch: branch, status: "active")

        if cart&.expired?
          cart.update!(status: "expired")
          cart = nil
        end

        cart || Cart.create!(
          customer: customer, branch: branch, status: "active",
          currency: branch.organization.default_currency, expires_at: TTL.from_now
        )
      end
    end
  end
end
