module Dispatch
  # Guarantees only one offer ever wins a delivery's assignment (section
  # 4.14): row-locks this offer to serialize a single courier's own
  # accept/reject, and relies on dispatch_offers' unique partial index
  # (status='accepted' per delivery_id) as the real race-safety backstop —
  # two different couriers accepting their own distinct offer rows for the
  # same delivery concurrently only lock their own row each, so the row
  # lock alone can't see the other; the DB constraint is what makes the
  # second one lose.
  class RespondToOffer
    def self.call(...) = new(...).call

    def initialize(offer:, courier:, accept:, rejection_reason: nil)
      @offer = offer
      @courier = courier
      @accept = accept
      @rejection_reason = rejection_reason
    end

    def call
      authorize!

      if @accept
        accept!
      else
        reject!
      end
    end

    private

    def authorize!
      return if @offer.courier_id == @courier.id

      raise ForbiddenError.new("this offer does not belong to this courier", code: "not_offer_courier")
    end

    def reject!
      ActiveRecord::Base.transaction do
        @offer.lock!
        ensure_still_pending!
        @offer.update!(status: "rejected", responded_at: Time.current, rejection_reason: @rejection_reason)
      end
      @offer
    end

    def accept!
      ActiveRecord::Base.transaction do
        @offer.lock!
        ensure_still_pending!
        @offer.update!(status: "accepted", responded_at: Time.current)

        Deliveries::TransitionDelivery.call(
          delivery: @offer.delivery, to_status: "accepted", actor_type: "system",
          extra_attrs: { courier_id: @courier.id }
        )

        DispatchOffer.where(delivery_id: @offer.delivery_id, status: "pending").where.not(id: @offer.id)
          .update_all(status: "cancelled", responded_at: Time.current)
      end
      @offer
    rescue ActiveRecord::RecordNotUnique
      raise ConflictError.new("another courier already won this delivery", code: "offer_already_won")
    end

    def ensure_still_pending!
      return if @offer.pending? && @offer.expires_at > Time.current

      raise ConflictError.new("this offer is no longer available", code: "offer_not_available")
    end
  end
end
