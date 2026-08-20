module Api
  module V1
    module Courier
      class VehiclesController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Courier::CourierScoped

        def create
          authorize current_courier, :update?
          vehicle = current_courier.vehicles.create!(vehicle_params)
          render json: vehicle_body(vehicle), status: :created
        end

        def update
          authorize current_courier, :update?
          vehicle = current_courier.vehicles.find(params[:id])
          vehicle.update!(vehicle_params)
          render json: vehicle_body(vehicle)
        end

        private

        def vehicle_params
          params.permit(:vehicle_type, :brand, :model, :color, :plate, :active)
        end

        def vehicle_body(vehicle)
          {
            id: vehicle.id, vehicle_type: vehicle.vehicle_type, brand: vehicle.brand, model: vehicle.model,
            color: vehicle.color, active: vehicle.active
          }
        end
      end
    end
  end
end
