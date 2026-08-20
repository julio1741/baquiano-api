module Deliveries
  # The endpoint list (section 6) only has one courier action here
  # ("Confirmar recogida") — there's no separate "start route" step, so
  # picked_up -> en_route is chained automatically right after, same
  # pattern as Orders::PlaceOrder chaining placed -> merchant_pending.
  class ConfirmPickup
    def self.call(...) = new(...).call

    def initialize(delivery:, courier:)
      @delivery = delivery
      @courier = courier
    end

    def call
      Deliveries::TransitionDelivery.call(
        delivery: @delivery, to_status: "picked_up", actor_type: "courier", actor_courier: @courier
      )
      Deliveries::TransitionDelivery.call(delivery: @delivery, to_status: "en_route", actor_type: "system")
    end
  end
end
