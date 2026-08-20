module Api
  module V1
    module Customer
      class MobilePaymentSubmissionsController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Customer::CustomerScoped

        def create
          order = current_customer.orders.find(params[:order_id])
          payment_intent = order.payment_intent
          authorize payment_intent, :submit_mobile_payment?

          submission = Payments::SubmitMobilePayment.call(
            payment_intent: payment_intent, reference: params[:reference], amount: params[:amount],
            paid_at: params[:paid_at] || Time.current, origin_bank_code: params[:origin_bank_code],
            destination_bank_code: params[:destination_bank_code],
            payer_document_masked: params[:payer_document_masked], payer_phone_masked: params[:payer_phone_masked],
            evidence_attachment_reference: params[:evidence_attachment_reference]
          )
          render json: submission_body(submission), status: :created
        end

        private

        def submission_body(submission)
          {
            id: submission.id, review_status: submission.review_status, amount: submission.amount,
            currency: submission.currency, paid_at: submission.paid_at
          }
        end
      end
    end
  end
end
