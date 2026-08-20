module Orders
  # Converts an already-priced Quote into a real Order. Never recomputes
  # totals — copies the quote's numbers verbatim (section 4.7: "no
  # recalcular pedidos históricos"). Idempotent per (customer, idempotency_key).
  #
  # payment_method decides where the order starts: mobile_payment needs
  # confirmation before the merchant ever sees it (payment_pending) —
  # Payments::TransitionPaymentIntent#sync_order! is what actually advances
  # it once that payment is confirmed. cash/pos_on_delivery skip straight
  # past the payment states since nothing is collected until delivery.
  class PlaceOrder
    PAYMENT_METHODS = %w[mobile_payment pos_on_delivery cash].freeze
    UPFRONT_CONFIRMATION_METHODS = %w[mobile_payment].freeze

    def self.call(...) = new(...).call

    def initialize(quote:, payment_method:, customer_notes: nil, idempotency_key:)
      @quote = quote
      @payment_method = payment_method
      @customer_notes = customer_notes
      @idempotency_key = idempotency_key
    end

    def call
      existing = Order.find_by(customer_id: @quote.customer_id, idempotency_key: @idempotency_key)
      return existing if existing

      unless PAYMENT_METHODS.include?(@payment_method)
        raise ValidationError.new("unknown payment method", code: "invalid_payment_method")
      end
      raise ConflictError.new("quote already used", code: "quote_already_used") if @quote.consumed?
      raise ConflictError.new("quote expired", code: "quote_expired") if @quote.expired?

      ActiveRecord::Base.transaction do
        @quote.consume!

        order = create_order!
        snapshot_items!(order)
        @quote.cart.update!(status: "converted")

        Events::Publish.call(aggregate: order, event_type: "OrderPlaced", payload: { order_id: order.id })
        Payments::CreatePaymentIntent.call(order: order)

        if order.current_status == "placed"
          Orders::TransitionOrder.call(order: order, to_status: "merchant_pending", actor_type: "system")
        end

        order
      end
    end

    private

    def create_order!
      branch = @quote.branch

      Order.create!(
        public_number: generate_public_number,
        customer: @quote.customer,
        organization: branch.organization,
        merchant: branch.merchant,
        branch: branch,
        address: @quote.address,
        quote: @quote,
        current_status: initial_status,
        payment_status: initial_payment_status,
        payment_method: @payment_method,
        fulfillment_type: "delivery",
        delivery_model: branch.delivery_model,
        currency: @quote.currency,
        subtotal_amount: @quote.subtotal_amount,
        discount_amount: @quote.discount_amount,
        tax_amount: @quote.tax_amount,
        delivery_fee_amount: @quote.delivery_fee_amount,
        service_fee_amount: @quote.service_fee_amount,
        total_amount: @quote.total_amount,
        exchange_rate: @quote.exchange_rate,
        exchange_rate_value: @quote.exchange_rate_value,
        customer_notes: @customer_notes,
        placed_at: Time.current,
        pricing_snapshot: @quote.pricing_snapshot,
        address_snapshot: address_snapshot,
        merchant_snapshot: merchant_snapshot,
        idempotency_key: @idempotency_key
      )
    end

    def requires_upfront_payment?
      UPFRONT_CONFIRMATION_METHODS.include?(@payment_method)
    end

    def initial_status
      requires_upfront_payment? ? "payment_pending" : "placed"
    end

    def initial_payment_status
      requires_upfront_payment? ? "pending" : "not_required"
    end

    def address_snapshot
      address = @quote.address
      {
        recipient_name: address.recipient_name,
        original_text: address.original_text,
        building: address.building,
        floor: address.floor,
        apartment: address.apartment,
        landmark: address.landmark,
        delivery_instructions: address.delivery_instructions
      }
    end

    def merchant_snapshot
      branch = @quote.branch
      { branch_name: branch.name, merchant_id: branch.merchant_id, organization_id: branch.organization_id }
    end

    def snapshot_items!(order)
      @quote.cart.cart_items.each do |cart_item|
        order_item = build_order_item(order, cart_item)

        cart_item.cart_item_modifiers.each do |cart_item_modifier|
          build_order_item_modifier(order_item, cart_item_modifier)
        end
      end
    end

    def build_order_item(order, cart_item)
      order.order_items.create!(
        source_product: cart_item.product,
        source_variant: cart_item.product_variant,
        sku_snapshot: cart_item.product.sku,
        name_snapshot: cart_item.product.name,
        description_snapshot: cart_item.product.description,
        variant_name_snapshot: cart_item.product_variant&.name,
        quantity: cart_item.quantity,
        unit_price_amount: cart_item.unit_price_amount_snapshot,
        tax_amount: item_tax(cart_item),
        discount_amount: 0,
        line_total_amount: cart_item.line_total,
        currency: cart_item.currency,
        notes: cart_item.notes,
        product_snapshot: {
          sku: cart_item.product.sku, name: cart_item.product.name,
          base_price_amount: cart_item.product.base_price_amount
        }
      )
    end

    def build_order_item_modifier(order_item, cart_item_modifier)
      order_item.order_item_modifiers.create!(
        source_modifier: cart_item_modifier.modifier,
        modifier_group_name_snapshot: cart_item_modifier.modifier.modifier_group.name,
        modifier_name_snapshot: cart_item_modifier.modifier.name,
        quantity: cart_item_modifier.quantity,
        unit_price_amount: cart_item_modifier.additional_price_amount_snapshot,
        total_amount: cart_item_modifier.additional_price_amount_snapshot * cart_item_modifier.quantity,
        currency: cart_item_modifier.currency
      )
    end

    def item_tax(cart_item)
      tax_rule = cart_item.product.tax_rule
      return 0 unless tax_rule&.active?

      tax_rule.apply(cart_item.line_total)
    end

    def generate_public_number
      loop do
        candidate = "BQ-#{Date.current.strftime('%Y%m%d')}-#{SecureRandom.alphanumeric(6).upcase}"
        break candidate unless Order.exists?(public_number: candidate)
      end
    end
  end
end
