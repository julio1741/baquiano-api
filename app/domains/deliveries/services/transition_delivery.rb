module Deliveries
  # The only legitimate way a Delivery's status ever changes (Delivery
  # itself rejects direct writes — see app/models/delivery.rb). Mirrors
  # Orders::TransitionOrder's shape (section 5 of the spec's transition
  # matrix), scoped to what a single courier's own delivery execution needs.
  #
  # Unlike orders, there is no dedicated idempotency-key ledger table for
  # deliveries (the spec's schema never defines one — see
  # docs/architecture/decisions.md). Idempotency here is simpler: replaying
  # a transition whose `to_status` matches the delivery's *current* status
  # is a no-op success rather than an error, since a courier's mobile app
  # retrying a timed-out request is the only realistic replay scenario.
  #
  # "assigned" vs "accepted" distinguishes how a courier ended up on this
  # delivery: winning a dispatch offer implies consent, so
  # Dispatch::RespondToOffer drives offered -> accepted directly. "assigned"
  # is reserved for an admin's manual override (deliveries:assign) — the
  # courier hasn't consented yet and must still confirm via #accept.
  class TransitionDelivery
    TRANSITIONS = {
      %w[pending_assignment offered] => { actor: :system, event_type: "CourierOfferCreated" },
      %w[pending_assignment assigned] => {
        actor: :system, timestamp_column: :assigned_at, event_type: "CourierAssigned"
      },
      %w[offered assigned] => { actor: :system, timestamp_column: :assigned_at, event_type: "CourierAssigned" },
      %w[offered accepted] => {
        actor: :system, timestamp_column: :accepted_at, also_set: [ :assigned_at ], event_type: "CourierAssigned"
      },
      %w[assigned accepted] => { actor: :courier, timestamp_column: :accepted_at, event_type: "CourierAssigned" },
      %w[accepted at_merchant] => {
        actor: :courier, timestamp_column: :arrived_at_merchant_at, event_type: "CourierArrivedAtMerchant"
      },
      %w[at_merchant picked_up] => { actor: :courier, timestamp_column: :picked_up_at, event_type: "OrderPickedUp" },
      %w[picked_up en_route] => { actor: :system, event_type: "OrderPickedUp" },
      %w[en_route at_customer] => {
        actor: :courier, timestamp_column: :arrived_at_customer_at, event_type: "CourierArrivedAtCustomer"
      },
      %w[at_customer delivered] => {
        actor: :courier, timestamp_column: :delivered_at, requires_pin: true, requires_captured_payment: true,
        event_type: "OrderDelivered"
      },
      %w[pending_assignment cancelled] => { actor: :system, event_type: "DeliveryFailed" },
      %w[offered cancelled] => { actor: :system, event_type: "DeliveryFailed" },
      %w[accepted failed] => {
        actor: :courier, timestamp_column: :failed_at, requires_reason: true, event_type: "DeliveryFailed"
      },
      %w[at_merchant failed] => {
        actor: :courier, timestamp_column: :failed_at, requires_reason: true, event_type: "DeliveryFailed"
      },
      %w[picked_up failed] => {
        actor: :courier, timestamp_column: :failed_at, requires_reason: true, event_type: "DeliveryFailed"
      },
      %w[en_route failed] => {
        actor: :courier, timestamp_column: :failed_at, requires_reason: true, event_type: "DeliveryFailed"
      },
      %w[at_customer failed] => {
        actor: :courier, timestamp_column: :failed_at, requires_reason: true, event_type: "DeliveryFailed"
      }
    }.freeze

    def self.call(...) = new(...).call

    def initialize(delivery:, to_status:, actor_type:, actor_courier: nil, failure_reason: nil, pin: nil,
                   extra_attrs: {})
      @delivery = delivery
      @to_status = to_status.to_s
      @actor_type = actor_type.to_s
      @actor_courier = actor_courier
      @extra_attrs = extra_attrs
      @failure_reason = failure_reason
      @pin = pin
    end

    def call
      ActiveRecord::Base.transaction do
        @delivery.lock!
        return @delivery if @delivery.status == @to_status

        rule = TRANSITIONS[[ @delivery.status, @to_status ]]
        unless rule
          raise ConflictError.new("cannot transition from #{@delivery.status} to #{@to_status}",
                                   code: "invalid_transition")
        end

        authorize!(rule)

        if rule[:requires_reason] && @failure_reason.blank?
          raise ValidationError.new("failure_reason is required for this transition", code: "failure_reason_required")
        end

        if rule[:requires_pin] && !@delivery.matches_pin?(@pin)
          raise ValidationError.new("PIN does not match", code: "delivery_pin_mismatch")
        end

        if rule[:requires_captured_payment] && !@delivery.order.payment_intent&.status_captured?
          raise ConflictError.new("payment for this order hasn't been captured yet", code: "payment_not_captured")
        end

        from_status = @delivery.status
        apply_status!(rule)
        Events::Publish.call(
          aggregate: @delivery, event_type: rule[:event_type],
          payload: { delivery_id: @delivery.id, order_id: @delivery.order_id, from_status: from_status,
                     to_status: @to_status }
        )
        sync_order_status!
        @delivery
      end
    end

    private

    # Keeps the customer/merchant-facing Order status in lockstep with the
    # courier's own delivery execution — e.g. a customer polling their
    # order sees "en_route" the moment the courier's app confirms pickup,
    # without either side having to remember to update the other.
    ORDER_STATUS_FOR_DELIVERY_STATUS = {
      "accepted" => "courier_assigned",
      "at_merchant" => "courier_at_merchant",
      "picked_up" => "picked_up",
      "en_route" => "en_route",
      "at_customer" => "courier_at_customer",
      "delivered" => "delivered",
      "failed" => "delivery_failed"
    }.freeze

    def sync_order_status!
      order_status = ORDER_STATUS_FOR_DELIVERY_STATUS[@to_status]
      return unless order_status

      Orders::TransitionOrder.call(order: @delivery.order, to_status: order_status, actor_type: "system")
    end

    def authorize!(rule)
      return if @actor_type == "system"

      case rule[:actor]
      when :courier
        unless @actor_courier && @delivery.courier_id == @actor_courier.id
          raise ForbiddenError.new("only the assigned courier can do this", code: "not_assigned_courier")
        end
      end
    end

    def apply_status!(rule)
      @delivery.status_change_authorized = true
      attrs = { status: @to_status }
      attrs[rule[:timestamp_column]] = Time.current if rule[:timestamp_column]
      Array(rule[:also_set]).each { |column| attrs[column] = Time.current }
      attrs[:failure_reason] = @failure_reason if rule[:requires_reason]
      attrs.merge!(@extra_attrs)
      @delivery.update!(attrs)
    end
  end
end
