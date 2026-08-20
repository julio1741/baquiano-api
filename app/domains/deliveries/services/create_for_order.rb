module Deliveries
  # Bridges Orders and Dispatch: called right after an order reaches
  # ready_for_pickup (merchant's mark_ready action). Creates the Delivery,
  # moves the order into courier_search, and makes a first attempt at
  # finding a courier — if none are available right now, the delivery is
  # simply left in pending_assignment for Dispatch::RetryPendingAssignmentsJob
  # to pick up later, since an order legitimately can sit in courier_search
  # for a while with nobody online yet.
  class CreateForOrder
    def self.call(...) = new(...).call

    def initialize(order:)
      @order = order
    end

    def call
      delivery = Delivery.create!(
        order: @order, branch: @order.branch, delivery_model: @order.delivery_model, status: "pending_assignment",
        pickup_location: @order.branch.location, dropoff_location: @order.address.location,
        delivery_pin: format("%04d", SecureRandom.random_number(10_000))
      )

      Orders::TransitionOrder.call(order: @order, to_status: "courier_search", actor_type: "system")

      begin
        Dispatch::CreateOffers.call(delivery: delivery)
      rescue ConflictError
        nil
      end

      delivery
    end
  end
end
