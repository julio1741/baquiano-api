module Idempotency
  # Generic idempotency for new call sites that don't warrant their own
  # bespoke idempotency_key column (most existing aggregates — Order,
  # PaymentIntent, Refund — already have one and keep it; this isn't a
  # retrofit). Replaying the same (actor, operation, key) with the same
  # request returns the original resource; replaying it with a
  # *different* request body is rejected rather than silently ignored.
  class Perform
    DEFAULT_TTL = 24.hours

    # Not the usual `def self.call(...) = new(...).call` shorthand — `...`
    # forwards a block to whichever call it's attached to (`new`, here),
    # not to both, so `#call`'s own `yield` would have nothing to yield to.
    def self.call(*args, **kwargs, &block)
      new(*args, **kwargs).call(&block)
    end

    def initialize(actor:, operation:, key:, request_digest:, ttl: DEFAULT_TTL)
      @actor = actor
      @operation = operation
      @key = key
      @request_digest = request_digest
      @ttl = ttl
    end

    def call
      existing = find_existing
      if existing
        if existing.request_digest != @request_digest
          raise ConflictError.new("idempotency key already used with a different request",
                                   code: "idempotency_key_conflict")
        end
        return existing.resource_type.constantize.find(existing.resource_id)
      end

      resource = yield
      IdempotencyRecord.create!(
        actor_type: @actor.class.name, actor_id: @actor.id, operation: @operation, key: @key,
        request_digest: @request_digest, response_status: 201, resource_type: resource.class.name,
        resource_id: resource.id, expires_at: @ttl.from_now
      )
      resource
    end

    private

    def find_existing
      record = IdempotencyRecord.find_by(actor_type: @actor.class.name, actor_id: @actor.id, operation: @operation,
                                          key: @key)
      return nil if record.nil? || record.expired?

      record
    end
  end
end
