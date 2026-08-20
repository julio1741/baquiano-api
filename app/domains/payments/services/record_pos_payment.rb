module Payments
  # Confirmed at the moment it happens (courier or merchant staff swiping
  # the card) — unlike mobile payment there's no separate review step,
  # the person present at the terminal IS the confirmation. terminal_owner
  # is deliberately a param, not hardcoded, since ownership of the POS
  # device and the receiving account varies (a merchant's own terminal vs.
  # a Baquiano-owned one carried by the courier).
  class RecordPosPayment
    def self.call(...) = new(...).call

    def initialize(payment_intent:, confirmed_by:, terminal_owner: nil, receipt_reference: nil,
                   terminal_identifier: nil, acquiring_account_reference: nil, evidence_attachment_reference: nil)
      @payment_intent = payment_intent
      @confirmed_by = confirmed_by
      @terminal_owner = terminal_owner
      @receipt_reference = receipt_reference
      @terminal_identifier = terminal_identifier
      @acquiring_account_reference = acquiring_account_reference
      @evidence_attachment_reference = evidence_attachment_reference
    end

    def call
      unless @payment_intent.status_created?
        raise ConflictError.new("this payment is not awaiting a POS confirmation", code: "unexpected_payment_status")
      end

      record = PosPaymentRecord.create!(
        payment_intent: @payment_intent, terminal_owner: @terminal_owner, confirmed_by_user: @confirmed_by,
        confirmed_at: Time.current, amount: @payment_intent.amount, currency: @payment_intent.currency,
        receipt_reference: @receipt_reference, terminal_identifier: @terminal_identifier,
        acquiring_account_reference: @acquiring_account_reference,
        evidence_attachment_reference: @evidence_attachment_reference
      )

      Payments::TransitionPaymentIntent.call(payment_intent: @payment_intent, to_status: "captured")

      record
    end
  end
end
