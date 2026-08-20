module Api
  module V1
    module Courier
      class SettlementsController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Courier::CourierScoped

        def index
          render json: current_courier.settlements.order(period_end: :desc).map { |s| settlement_body(s) }
        end

        private

        def settlement_body(settlement)
          {
            id: settlement.id, period_start: settlement.period_start, period_end: settlement.period_end,
            currency: settlement.currency, gross_amount: settlement.gross_amount,
            commission_amount: settlement.commission_amount, adjustment_amount: settlement.adjustment_amount,
            net_amount: settlement.net_amount, status: settlement.status, paid_at: settlement.paid_at
          }
        end
      end
    end
  end
end
