module Cash
  class InitiateHandover
    def self.call(...) = new(...).call

    def initialize(courier:, received_by:, amount:, idempotency_key:, evidence_attachment_reference: nil, notes: nil)
      @courier = courier
      @received_by = received_by
      @amount = amount
      @idempotency_key = idempotency_key
      @evidence_attachment_reference = evidence_attachment_reference
      @notes = notes
    end

    def call
      existing = CashHandover.find_by(courier: @courier, idempotency_key: @idempotency_key)
      return existing if existing

      balance = CashBalance.find_by(courier: @courier)
      if balance.nil? || @amount > balance.amount_held
        raise ValidationError.new("handover amount exceeds cash currently held", code: "handover_amount_too_high")
      end

      CashHandover.create!(
        courier: @courier, received_by_user: @received_by, amount: @amount, currency: balance.currency,
        idempotency_key: @idempotency_key, evidence_attachment_reference: @evidence_attachment_reference,
        notes: @notes, handed_over_at: Time.current, status: "pending"
      )
    end
  end
end
