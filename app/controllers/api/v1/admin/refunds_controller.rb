module Api
  module V1
    module Admin
      class RefundsController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize Refund.new, :show?
          refunds = Refund.all
          refunds = refunds.where(status: params[:status]) if params[:status].present?
          render json: refunds.order(requested_at: :desc).map { |refund| refund_body(refund) }
        end

        def show
          refund = Refund.find(params[:id])
          authorize refund
          render json: refund_body(refund)
        end

        def approve
          refund = Refund.find(params[:id])
          authorize refund, :decide?
          Payments::DecideRefund.call(refund: refund, decided_by: current_user, approve: true)
          render json: refund_body(refund.reload)
        end

        def reject
          refund = Refund.find(params[:id])
          authorize refund, :decide?
          Payments::DecideRefund.call(
            refund: refund, decided_by: current_user, approve: false, failure_code: params[:failure_code]
          )
          render json: refund_body(refund.reload)
        end

        private

        def refund_body(refund)
          {
            id: refund.id, order_id: refund.order_id, status: refund.status, reason_code: refund.reason_code,
            reason_notes: refund.reason_notes, amount: refund.amount, currency: refund.currency,
            requested_by_user_id: refund.requested_by_user_id, approved_by_user_id: refund.approved_by_user_id,
            requested_at: refund.requested_at, completed_at: refund.completed_at, failure_code: refund.failure_code
          }
        end
      end
    end
  end
end
