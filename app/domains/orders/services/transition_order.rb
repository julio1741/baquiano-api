module Orders
  # The only legitimate way current_status ever changes (Order itself
  # rejects direct writes — see app/models/order.rb). Section 5 of the
  # spec's transition matrix, scoped to what doesn't need Payments/Dispatch
  # (both still unbuilt — see docs/architecture/decisions.md): the order
  # lifecycle up through ready_for_pickup, plus cancellation.
  #
  # Idempotency: a user-initiated request (actor_user + idempotency_key)
  # gets an OrderTransitionRequest row created *before* attempting anything,
  # in its own commit — so if the transition itself fails and rolls back,
  # the failure is still durably recorded, and a retry with the same key
  # short-circuits to the original outcome instead of re-processing.
  # System-initiated transitions (placed -> merchant_pending, right after
  # PlaceOrder) skip this ledger entirely; PlaceOrder's own idempotency
  # already prevents them from running twice.
  class TransitionOrder
    TRANSITIONS = {
      %w[placed merchant_pending] => { actor: :system, event_type: "OrderStatusChanged" },
      # Driven by Payments::TransitionPaymentIntent#sync_order! once a
      # mobile_payment order's payment is actually confirmed (Increment 6)
      # — this was a dead end from Increment 4 until Payments existed.
      %w[payment_pending placed] => { actor: :system, event_type: "PaymentConfirmed" },
      %w[payment_pending cancelled] => {
        actor: :customer, timestamp_column: :cancelled_at, event_type: "OrderCancelled"
      },
      %w[merchant_pending merchant_accepted] => {
        actor: :merchant_staff, permission: "orders:update_status",
        timestamp_column: :merchant_accepted_at, event_type: "MerchantAcceptedOrder"
      },
      %w[merchant_pending merchant_rejected] => {
        actor: :merchant_staff, permission: "orders:update_status", requires_reason: true,
        event_type: "MerchantRejectedOrder"
      },
      %w[merchant_pending cancelled] => {
        actor: :customer, timestamp_column: :cancelled_at, event_type: "OrderCancelled"
      },
      %w[merchant_accepted preparing] => {
        actor: :merchant_staff, permission: "orders:update_status", event_type: "OrderPreparationStarted"
      },
      %w[merchant_accepted cancellation_requested] => { actor: :customer, event_type: "OrderStatusChanged" },
      %w[preparing ready_for_pickup] => {
        actor: :merchant_staff, permission: "orders:update_status",
        timestamp_column: :ready_at, event_type: "OrderReadyForPickup"
      },
      %w[preparing cancellation_requested] => { actor: :customer, event_type: "OrderStatusChanged" },
      %w[cancellation_requested cancelled] => {
        actor: :merchant_staff, permission: "orders:update_status",
        timestamp_column: :cancelled_at, event_type: "OrderCancelled"
      },
      %w[merchant_rejected closed] => { actor: :system, event_type: "OrderStatusChanged" },
      %w[cancelled closed] => { actor: :system, event_type: "OrderStatusChanged" },

      # From here on, driven by Deliveries::TransitionDelivery's own status
      # changes (Dispatch/Deliveries domains, Increment 5) — never called
      # directly from a controller, always actor: system.
      %w[ready_for_pickup courier_search] => { actor: :system, event_type: "OrderStatusChanged" },
      %w[courier_search courier_assigned] => { actor: :system, event_type: "CourierAssigned" },
      %w[courier_assigned courier_at_merchant] => { actor: :system, event_type: "CourierArrivedAtMerchant" },
      %w[courier_at_merchant picked_up] => {
        actor: :system, timestamp_column: :picked_up_at, event_type: "OrderPickedUp"
      },
      %w[picked_up en_route] => { actor: :system, event_type: "OrderStatusChanged" },
      %w[en_route courier_at_customer] => { actor: :system, event_type: "CourierArrivedAtCustomer" },
      %w[courier_at_customer delivered] => {
        actor: :system, timestamp_column: :delivered_at, event_type: "OrderDelivered"
      },
      %w[courier_search delivery_failed] => { actor: :system, event_type: "DeliveryFailed" },
      %w[courier_assigned delivery_failed] => { actor: :system, event_type: "DeliveryFailed" },
      %w[courier_at_merchant delivery_failed] => { actor: :system, event_type: "DeliveryFailed" },
      %w[picked_up delivery_failed] => { actor: :system, event_type: "DeliveryFailed" },
      %w[en_route delivery_failed] => { actor: :system, event_type: "DeliveryFailed" },
      %w[courier_at_customer delivery_failed] => { actor: :system, event_type: "DeliveryFailed" },

      # Driven by Payments::RequestRefund/DecideRefund (Increment 6).
      %w[delivered refund_pending] => { actor: :system, event_type: "RefundRequested" },
      %w[merchant_rejected refund_pending] => { actor: :system, event_type: "RefundRequested" },
      %w[cancelled refund_pending] => { actor: :system, event_type: "RefundRequested" },
      %w[refund_pending refunded] => { actor: :system, event_type: "RefundCompleted" },
      %w[refund_pending partially_refunded] => { actor: :system, event_type: "RefundCompleted" },
      %w[partially_refunded refunded] => { actor: :system, event_type: "RefundCompleted" }
    }.freeze

    def self.call(...) = new(...).call

    def initialize(order:, to_status:, actor_type:, actor_user: nil, reason_code: nil, notes: nil, idempotency_key: nil)
      @order = order
      @to_status = to_status.to_s
      @actor_type = actor_type.to_s
      @actor_user = actor_user
      @reason_code = reason_code
      @notes = notes
      @idempotency_key = idempotency_key
    end

    def call
      request = find_or_create_request
      return @order if request&.succeeded?

      begin
        perform!
        request&.update!(status: "succeeded", processed_at: Time.current)
        @order
      rescue ApplicationError => e
        request&.update!(status: "failed", failure_code: e.code, failure_message: e.message, processed_at: Time.current)
        raise
      end
    end

    private

    def find_or_create_request
      return nil unless @idempotency_key && @actor_user

      OrderTransitionRequest.find_or_create_by!(order_id: @order.id, idempotency_key: @idempotency_key) do |r|
        r.requested_transition = @to_status
        r.requested_by_user = @actor_user
        r.status = "pending"
      end
    end

    def perform!
      ActiveRecord::Base.transaction do
        @order.lock!
        from_status = @order.current_status
        rule = TRANSITIONS[[ from_status, @to_status ]]
        unless rule
          raise ConflictError.new("cannot transition from #{from_status} to #{@to_status}", code: "invalid_transition")
        end

        authorize!(rule)

        if rule[:requires_reason] && @reason_code.blank?
          raise ValidationError.new("reason_code is required for this transition", code: "reason_code_required")
        end

        apply_status!(rule, from_status)
        record_history!(from_status)
        Events::Publish.call(
          aggregate: @order, event_type: rule[:event_type],
          payload: { order_id: @order.id, from_status: from_status, to_status: @to_status }
        )
        notify_customer!
      end
    end

    # A curated subset, not every transition — courier_search/picked_up/
    # en_route are tracking-screen detail, not push-worthy on their own.
    CUSTOMER_NOTIFICATION_TEMPLATES = {
      "merchant_accepted" => "order_accepted",
      "merchant_rejected" => "order_rejected",
      "ready_for_pickup" => "order_ready_for_pickup",
      "courier_assigned" => "courier_assigned",
      "delivered" => "order_delivered",
      "cancelled" => "order_cancelled",
      "refunded" => "order_refunded",
      "partially_refunded" => "order_partially_refunded"
    }.freeze

    def notify_customer!
      template_code = CUSTOMER_NOTIFICATION_TEMPLATES[@to_status]
      return unless template_code

      Notifications::Send.call(
        user: @order.customer.user, channel: "push", template_code: template_code, order: @order,
        idempotency_key: "#{template_code}:#{@order.id}"
      )
    end

    def authorize!(rule)
      # A caller that self-identifies as "system" (internal jobs/services —
      # never derived from client input) is trusted to force any
      # transition, e.g. auto-cancelling on a merchant-acceptance timeout,
      # which reaches the same merchant_pending -> cancelled rule a
      # customer-initiated cancellation uses.
      return if @actor_type == "system"

      case rule[:actor]
      when :customer
        unless @actor_user && @order.customer.user_id == @actor_user.id
          raise ForbiddenError.new("only the order's own customer can do this", code: "not_order_customer")
        end
      when :merchant_staff
        allowed = @actor_user && AccessControl::HasPermission.call(
          user: @actor_user, code: rule[:permission], organization_id: @order.organization_id, branch_id: @order.branch_id
        )
        raise ForbiddenError.new("missing permission for this transition", code: "forbidden_transition") unless allowed
      end
    end

    def apply_status!(rule, _from_status)
      @order.status_change_authorized = true
      attrs = { current_status: @to_status }
      attrs[rule[:timestamp_column]] = Time.current if rule[:timestamp_column]
      if %w[merchant_rejected cancelled].include?(@to_status)
        attrs[:cancellation_reason_code] = @reason_code if @reason_code.present?
        attrs[:cancellation_notes] = @notes if @notes.present?
      end
      @order.update!(attrs)
    end

    def record_history!(from_status)
      OrderStatusHistory.create!(
        order: @order, from_status: from_status, to_status: @to_status, actor_user: @actor_user,
        actor_type: @actor_type, reason_code: @reason_code, notes: @notes, occurred_at: Time.current
      )
    end
  end
end
