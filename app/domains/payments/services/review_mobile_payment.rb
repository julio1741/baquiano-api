module Payments
  class ReviewMobilePayment
    def self.call(...) = new(...).call

    def initialize(submission:, reviewed_by:, approve:, rejection_reason: nil)
      @submission = submission
      @reviewed_by = reviewed_by
      @approve = approve
      @rejection_reason = rejection_reason
    end

    def call
      unless @submission.submitted? || @submission.under_review? || @submission.duplicate?
        raise ConflictError.new("this submission has already been reviewed", code: "already_reviewed")
      end

      if @approve
        approve!
      else
        reject!
      end
    end

    private

    def approve!
      @submission.update!(review_status: "confirmed", reviewed_by_user: @reviewed_by, reviewed_at: Time.current)
      Payments::TransitionPaymentIntent.call(payment_intent: @submission.payment_intent, to_status: "captured")
      @submission
    end

    def reject!
      @submission.update!(
        review_status: "rejected", reviewed_by_user: @reviewed_by, reviewed_at: Time.current,
        rejection_reason: @rejection_reason
      )
      Payments::TransitionPaymentIntent.call(
        payment_intent: @submission.payment_intent, to_status: "failed", failure_code: "mobile_payment_rejected",
        failure_message: @rejection_reason
      )
      @submission
    end
  end
end
