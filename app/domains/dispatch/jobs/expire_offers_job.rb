module Dispatch
  # Section 8 of the spec: "Expiración de ofertas de despacho". A courier
  # who doesn't respond in time loses the offer; if that was the delivery's
  # last outstanding offer, immediately try to find new candidates so the
  # order doesn't sit in courier_search indefinitely.
  class ExpireOffersJob < ApplicationJob
    queue_as :maintenance

    def perform
      expire_stale_offers
      retry_deliveries_with_no_pending_offers
    end

    private

    def expire_stale_offers
      DispatchOffer.where(status: "pending").where(expires_at: ...Time.current).find_each do |offer|
        # An offer can go stale after its delivery was already resolved by a
        # different offer accepting first — that's a cancellation, not an
        # expiration (Dispatch::RespondToOffer just hasn't gotten to it yet
        # for whatever reason, e.g. if it ran outside a transaction once).
        new_status = offer.delivery.status_offered? ? "expired" : "cancelled"
        offer.update!(status: new_status, responded_at: Time.current)
      end
    end

    def retry_deliveries_with_no_pending_offers
      Delivery.status_offered.find_each do |delivery|
        next if delivery.dispatch_offers.where(status: "pending").exists?

        Dispatch::CreateOffers.call(delivery: delivery)
      rescue ConflictError
        next
      end
    end
  end
end
