module Api
  module V1
    module Courier
      class CashBalancesController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Courier::CourierScoped

        def index
          render json: current_courier.cash_balances.map { |balance| balance_body(balance) }
        end

        private

        def balance_body(balance)
          {
            id: balance.id, currency: balance.currency, amount_held: balance.amount_held,
            exposure_limit: balance.exposure_limit, blocked_for_cash_orders: balance.blocked_for_cash_orders,
            calculated_at: balance.calculated_at
          }
        end
      end
    end
  end
end
