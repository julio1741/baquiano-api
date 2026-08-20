module Api
  module V1
    module Courier
      class AvailabilitiesController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Courier::CourierScoped

        def create
          authorize current_courier, :update?
          availability = Couriers::SetAvailability.call(
            courier: current_courier, status: params[:status], zone_id: params[:zone_id]
          )
          render json: availability_body(availability), status: :created
        end

        private

        def availability_body(availability)
          return { status: "offline" } unless availability

          { id: availability.id, status: availability.status, zone_id: availability.zone_id,
            started_at: availability.started_at }
        end
      end
    end
  end
end
