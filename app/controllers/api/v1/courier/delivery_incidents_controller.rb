module Api
  module V1
    module Courier
      class DeliveryIncidentsController < Api::V1::BaseController
        include Authenticatable
        include Api::V1::Courier::CourierScoped

        def create
          delivery = current_courier.deliveries.find(params[:delivery_id])
          incident = DeliveryIncident.create!(
            delivery: delivery, order: delivery.order, reported_by_user: current_user,
            incident_type: params[:incident_type], severity: params[:severity] || "medium",
            description: params[:description], occurred_at: Time.current
          )
          render json: incident_body(incident), status: :created
        end

        private

        def incident_body(incident)
          { id: incident.id, incident_type: incident.incident_type, severity: incident.severity,
            status: incident.status, occurred_at: incident.occurred_at }
        end
      end
    end
  end
end
