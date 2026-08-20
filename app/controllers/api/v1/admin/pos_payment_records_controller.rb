module Api
  module V1
    module Admin
      # Read-only — a POS payment self-confirms at the moment it's
      # recorded (Payments::RecordPosPayment), there's nothing left for an
      # admin to approve, only to audit.
      class PosPaymentRecordsController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize PaymentIntent.new, :review?
          render json: PosPaymentRecord.order(created_at: :desc).map { |record| record_body(record) }
        end

        private

        def record_body(record)
          {
            id: record.id, payment_intent_id: record.payment_intent_id, amount: record.amount,
            currency: record.currency, status: record.status, receipt_reference: record.receipt_reference,
            confirmed_by_user_id: record.confirmed_by_user_id, confirmed_at: record.confirmed_at
          }
        end
      end
    end
  end
end
