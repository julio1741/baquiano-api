# NOTE: references the Courier model as ::Courier throughout — same
# Api::V1::Courier namespace collision documented in
# docs/architecture/domains.md for Merchant/Customer.
module Api
  module V1
    module Admin
      class CouriersController < Api::V1::BaseController
        include Authenticatable

        def index
          authorize ::Courier
          couriers = ::Courier.all
          couriers = couriers.where(approval_status: params[:approval_status]) if params[:approval_status].present?
          render json: couriers.map { |courier| courier_body(courier) }
        end

        def show
          courier = ::Courier.find(params[:id])
          authorize courier
          render json: courier_body(courier)
        end

        def update
          courier = ::Courier.find(params[:id])
          authorize courier, :manage?
          courier.update!(courier_params)
          render json: courier_body(courier)
        end

        def approve
          courier = ::Courier.find(params[:id])
          authorize courier
          courier.approve!
          Audit::RecordEvent.call(action: "courier.approved", resource_type: "Courier", resource_id: courier.id,
                                   request: request)
          render json: courier_body(courier)
        end

        def reject
          courier = ::Courier.find(params[:id])
          authorize courier
          courier.reject!(reason: params[:reason])
          Audit::RecordEvent.call(action: "courier.rejected", resource_type: "Courier", resource_id: courier.id,
                                   metadata: { reason: params[:reason] }, request: request)
          render json: courier_body(courier)
        end

        def suspend
          courier = ::Courier.find(params[:id])
          authorize courier
          courier.suspend!(reason: params[:reason])
          Audit::RecordEvent.call(action: "courier.suspended", resource_type: "Courier", resource_id: courier.id,
                                   metadata: { reason: params[:reason] }, request: request)
          render json: courier_body(courier)
        end

        private

        def courier_params
          params.permit(:organization_id, :courier_type, :risk_level, :cash_enabled, :maximum_cash_exposure)
        end

        def courier_body(courier)
          {
            id: courier.id,
            user_id: courier.user_id,
            organization_id: courier.organization_id,
            courier_type: courier.courier_type,
            status: courier.status,
            approval_status: courier.approval_status,
            risk_level: courier.risk_level,
            cash_enabled: courier.cash_enabled,
            approved_at: courier.approved_at,
            suspended_at: courier.suspended_at,
            suspension_reason: courier.suspension_reason
          }
        end
      end
    end
  end
end
