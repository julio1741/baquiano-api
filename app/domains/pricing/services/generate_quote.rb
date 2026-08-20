module Pricing
  # The one place totals get computed — the client never sends a trustworthy
  # total (section 4.7 of the spec). Idempotent: replaying the same
  # (customer, idempotency_key) returns the original quote rather than
  # recomputing, so a retried request can't double-charge or drift.
  #
  # service_fee_amount is always 0 — there's no service-fee configuration
  # table in this MVP; nothing to compute yet.
  class GenerateQuote
    TTL = 10.minutes

    def self.call(...) = new(...).call

    def initialize(cart:, address:, idempotency_key:)
      @cart = cart
      @address = address
      @idempotency_key = idempotency_key
    end

    def call
      existing = Quote.find_by(customer_id: @cart.customer_id, idempotency_key: @idempotency_key)
      return existing if existing

      raise ConflictError.new("cart has no items", code: "cart_empty") if @cart.cart_items.none?
      unless @cart.customer_id == @address.customer_id
        raise ValidationError.new("address does not belong to this customer", code: "address_customer_mismatch")
      end

      subtotal = @cart.cart_items.sum(&:line_total)
      tax = @cart.cart_items.sum { |item| tax_for(item) }
      delivery_fee = delivery_fee_for(@address)
      total = subtotal + tax + delivery_fee

      Quote.create!(
        cart: @cart,
        customer: @cart.customer,
        branch: @cart.branch,
        address: @address,
        currency: @cart.currency,
        subtotal_amount: subtotal,
        tax_amount: tax,
        delivery_fee_amount: delivery_fee,
        service_fee_amount: 0,
        total_amount: total,
        expires_at: TTL.from_now,
        idempotency_key: @idempotency_key,
        pricing_snapshot: { subtotal_amount: subtotal, tax_amount: tax, delivery_fee_amount: delivery_fee,
                            total_amount: total }
      )
    end

    private

    def tax_for(item)
      tax_rule = item.product.tax_rule
      return 0 unless tax_rule&.active?

      tax_rule.apply(item.line_total)
    end

    def delivery_fee_for(address)
      rule = DeliveryFeeRule.where(city_id: address.city_id, active: true)
        .where("valid_from <= ?", Date.current)
        .where("valid_until IS NULL OR valid_until >= ?", Date.current)
        .first
      return 0 unless rule

      rule.fee_for(distance_meters: distance_meters_to(address))
    end

    # Real geographic distance via PostGIS (ST_Distance on geography), not a
    # Ruby approximation.
    def distance_meters_to(address)
      sql = ActiveRecord::Base.sanitize_sql_array([
        "SELECT ST_Distance(ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography, " \
        "ST_SetSRID(ST_MakePoint(?, ?), 4326)::geography)",
        @cart.branch.location.x, @cart.branch.location.y, address.location.x, address.location.y
      ])
      ActiveRecord::Base.connection.select_value(sql).to_f
    end
  end
end
