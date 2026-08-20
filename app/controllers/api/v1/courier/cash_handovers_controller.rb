module Api
  module V1
    module Courier
      class CashHandoversController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Courier::CourierScoped

        def index
          render json: current_courier.cash_handovers.order(created_at: :desc).map { |h| handover_body(h) }
        end

        def create
          received_by = User.find(params[:received_by_user_id])
          handover = Cash::InitiateHandover.call(
            courier: current_courier, received_by: received_by, amount: params[:amount],
            idempotency_key: params.fetch(:idempotency_key), evidence_attachment_reference: params[:evidence_attachment_reference],
            notes: params[:notes]
          )
          render json: handover_body(handover), status: :created
        end

        private

        def handover_body(handover)
          {
            id: handover.id, amount: handover.amount, currency: handover.currency, status: handover.status,
            handed_over_at: handover.handed_over_at, confirmed_at: handover.confirmed_at
          }
        end
      end
    end
  end
end
