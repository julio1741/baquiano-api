# NOTE: references the Courier model as ::Courier throughout — bare
# `Courier` inside Api::V1::Courier::* resolves to the Api::V1::Courier
# routing namespace module instead (same trap documented for Merchant and
# Customer in docs/architecture/domains.md).
module Api
  module V1
    module Courier
      class CouriersController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Courier::CourierScoped

        def show
          authorize current_courier
          render json: courier_body(current_courier)
        end

        def create
          courier = ::Courier.new(courier_params.merge(user: current_user))
          authorize courier
          courier.save!
          render json: courier_body(courier), status: :created
        end

        def update
          authorize current_courier
          current_courier.update!(courier_params)
          render json: courier_body(current_courier)
        end

        private

        # risk_level and cash_enabled are deliberately excluded — those are
        # admin-only fields (Api::V1::Admin::CouriersController), never
        # self-settable. See CourierPolicy#manage?.
        def courier_params
          params.permit(:courier_type)
        end

        def courier_body(courier)
          {
            id: courier.id,
            courier_type: courier.courier_type,
            status: courier.status,
            approval_status: courier.approval_status,
            cash_enabled: courier.cash_enabled,
            approved_at: courier.approved_at
          }
        end
      end
    end
  end
end
