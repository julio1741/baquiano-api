module Api
  module V1
    module Admin
      class MobilePaymentSubmissionsController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize PaymentIntent.new, :review?
          submissions = MobilePaymentSubmission.where(review_status: %w[submitted under_review duplicate])
            .order(created_at: :asc)
          render json: submissions.map { |s| submission_body(s) }
        end

        def show
          submission = MobilePaymentSubmission.find(params[:id])
          authorize submission.payment_intent, :review?
          render json: submission_body(submission)
        end

        def approve
          submission = MobilePaymentSubmission.find(params[:id])
          authorize submission.payment_intent, :review?
          Payments::ReviewMobilePayment.call(submission: submission, reviewed_by: current_user, approve: true)
          render json: submission_body(submission.reload)
        end

        def reject
          submission = MobilePaymentSubmission.find(params[:id])
          authorize submission.payment_intent, :review?
          Payments::ReviewMobilePayment.call(
            submission: submission, reviewed_by: current_user, approve: false,
            rejection_reason: params[:rejection_reason]
          )
          render json: submission_body(submission.reload)
        end

        private

        def submission_body(submission)
          {
            id: submission.id, payment_intent_id: submission.payment_intent_id, reference: submission.reference,
            amount: submission.amount, currency: submission.currency, paid_at: submission.paid_at,
            review_status: submission.review_status, duplicate_of_submission_id: submission.duplicate_of_submission_id,
            rejection_reason: submission.rejection_reason
          }
        end
      end
    end
  end
end
