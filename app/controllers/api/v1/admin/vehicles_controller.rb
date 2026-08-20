module Api
  module V1
    module Admin
      class VehiclesController < Api::V1::BaseController
        include Authenticatable

        def index
          courier = ::Courier.find(params[:courier_id])
          authorize courier, :manage?
          render json: courier.vehicles.map { |vehicle| vehicle_body(vehicle) }
        end

        def update
          vehicle = Vehicle.find(params[:id])
          authorize vehicle.courier, :manage?
          vehicle.update!(vehicle_params)
          render json: vehicle_body(vehicle)
        end

        private

        def vehicle_params
          params.permit(:active)
        end

        def vehicle_body(vehicle)
          {
            id: vehicle.id, courier_id: vehicle.courier_id, vehicle_type: vehicle.vehicle_type,
            brand: vehicle.brand, model: vehicle.model, color: vehicle.color, active: vehicle.active
          }
        end
      end
    end
  end
end
