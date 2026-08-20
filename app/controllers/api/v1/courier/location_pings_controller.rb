module Api
  module V1
    module Courier
      class LocationPingsController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Courier::CourierScoped

        def create
          delivery = current_courier.deliveries.find_by(id: params[:delivery_id])
          ping = Deliveries::RecordLocationPing.call(
            courier: current_courier, delivery: delivery, latitude: params[:latitude].to_f,
            longitude: params[:longitude].to_f, device_recorded_at: params[:device_recorded_at] || Time.current,
            source: params[:source] || "gps", accuracy_meters: params[:accuracy_meters],
            speed_meters_per_second: params[:speed_meters_per_second], heading_degrees: params[:heading_degrees]
          )
          render json: { id: ping.id, server_received_at: ping.server_received_at }, status: :created
        end
      end
    end
  end
end
