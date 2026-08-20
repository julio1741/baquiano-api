module Payments
  # Section 8/10, scenario 5: "Referencia de Pago Móvil reutilizada".
  # Payments::SubmitMobilePayment already catches this synchronously for
  # the common case (a reference reused against a submission that already
  # exists), but two submissions sharing a reference can still both start
  # out unflagged if they're created concurrently before either is visible
  # to the other's lookup. This periodic sweep is the defense-in-depth
  # backstop for that race — it never touches an already-decided
  # (confirmed/rejected) submission, only ones still awaiting review.
  class DetectDuplicatePaymentsJob < ApplicationJob
    queue_as :maintenance

    def perform
      duplicate_digests.each { |digest| flag_group(digest) }
    end

    private

    def duplicate_digests
      MobilePaymentSubmission.group(:reference_digest).having("count(*) > 1").count.keys
    end

    def flag_group(digest)
      submissions = MobilePaymentSubmission.where(reference_digest: digest).order(:created_at)
      original = submissions.first

      submissions.offset(1).each do |submission|
        next unless submission.submitted? || submission.under_review?

        submission.update!(duplicate_of_submission: original, review_status: "duplicate")
      end
    end
  end
end
