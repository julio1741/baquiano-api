module Api
  module V1
    module Admin
      class CashHandoversController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize CashHandover.new, :show?
          handovers = CashHandover.all
          handovers = handovers.where(status: params[:status]) if params[:status].present?
          render json: handovers.order(created_at: :desc).map { |h| handover_body(h) }
        end

        def confirm
          handover = CashHandover.find(params[:id])
          authorize handover, :confirm?
          Cash::ConfirmHandover.call(handover: handover)
          render json: handover_body(handover.reload)
        end

        private

        def handover_body(handover)
          {
            id: handover.id, courier_id: handover.courier_id, amount: handover.amount, currency: handover.currency,
            status: handover.status, handed_over_at: handover.handed_over_at, confirmed_at: handover.confirmed_at
          }
        end
      end
    end
  end
end
