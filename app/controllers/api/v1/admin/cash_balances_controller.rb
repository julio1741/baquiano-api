module Api
  module V1
    module Admin
      class CashBalancesController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize CashBalance.new, :show?
          render json: CashBalance.all.map { |balance| balance_body(balance) }
        end

        def update
          balance = CashBalance.find(params[:id])
          authorize balance, :manage?
          balance.update!(balance_params)
          render json: balance_body(balance)
        end

        private

        def balance_params
          params.permit(:exposure_limit, :blocked_for_cash_orders)
        end

        def balance_body(balance)
          {
            id: balance.id, courier_id: balance.courier_id, currency: balance.currency,
            amount_held: balance.amount_held, exposure_limit: balance.exposure_limit,
            blocked_for_cash_orders: balance.blocked_for_cash_orders
          }
        end
      end
    end
  end
end
