module Api
  module V1
    module Customer
      class RefundsController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Customer::CustomerScoped

        def create
          order = current_customer.orders.find(params[:order_id])
          authorize Refund.new(order: order), :request?

          refund = Payments::RequestRefund.call(
            order: order, requested_by: current_user, reason_code: params[:reason_code], amount: params[:amount],
            reason_notes: params[:reason_notes], idempotency_key: params.fetch(:idempotency_key)
          )
          render json: refund_body(refund), status: :created
        end

        private

        def refund_body(refund)
          {
            id: refund.id, status: refund.status, reason_code: refund.reason_code, amount: refund.amount,
            currency: refund.currency, requested_at: refund.requested_at
          }
        end
      end
    end
  end
end
