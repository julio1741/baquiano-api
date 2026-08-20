module Payments
  # Never confirms automatically from the submission itself (section 16:
  # "No confirmar pagos mediante una imagen") — this only records what the
  # customer says they paid; a human always reviews it
  # (Payments::ReviewMobilePayment). A reused reference (checked globally,
  # not just within this payment_intent — the meaningful fraud signal is
  # the same reference appearing on a *different* order) is still recorded
  # and routed to review, flagged as "duplicate" rather than silently
  # rejected, since a legitimate re-submission (e.g. a typo'd first
  # attempt) is also possible.
  class SubmitMobilePayment
    def self.call(...) = new(...).call

    def initialize(payment_intent:, reference:, amount:, paid_at:, origin_bank_code: nil,
                   destination_bank_code: nil, payer_document_masked: nil, payer_phone_masked: nil,
                   evidence_attachment_reference: nil)
      @payment_intent = payment_intent
      @reference = reference
      @amount = amount
      @paid_at = paid_at
      @origin_bank_code = origin_bank_code
      @destination_bank_code = destination_bank_code
      @payer_document_masked = payer_document_masked
      @payer_phone_masked = payer_phone_masked
      @evidence_attachment_reference = evidence_attachment_reference
    end

    def call
      unless @payment_intent.status_pending_customer_action?
        raise ConflictError.new("this payment is not waiting for a submission", code: "unexpected_payment_status")
      end

      duplicate = MobilePaymentSubmission.find_by(reference_digest: BlindIndex.digest(@reference))

      submission = MobilePaymentSubmission.create!(
        payment_intent: @payment_intent, reference: @reference, amount: @amount, currency: @payment_intent.currency,
        paid_at: @paid_at, origin_bank_code: @origin_bank_code, destination_bank_code: @destination_bank_code,
        payer_document_masked: @payer_document_masked, payer_phone_masked: @payer_phone_masked,
        evidence_attachment_reference: @evidence_attachment_reference, duplicate_of_submission: duplicate,
        review_status: duplicate ? "duplicate" : "submitted"
      )

      Payments::TransitionPaymentIntent.call(payment_intent: @payment_intent, to_status: "pending_review")

      submission
    end
  end
end
