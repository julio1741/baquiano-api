module Api
  module V1
    module Admin
      class AuditEventsController < Api::V1::BaseController
        include Authenticatable

        LIST_LIMIT = 200

        def index
          authorize AuditEvent
          events = AuditEvent.all
          events = events.where(resource_type: params[:resource_type]) if params[:resource_type].present?
          events = events.where(resource_id: params[:resource_id]) if params[:resource_id].present?
          # Filter param is audit_action, not action — params[:action] is
          # Rails' own reserved controller-action name (always "index"
          # here), not something a caller can ever meaningfully set.
          events = events.where(action: params[:audit_action]) if params[:audit_action].present?
          events = events.order(occurred_at: :desc)

          page = events.limit(LIST_LIMIT).to_a
          render json: {
            events: page.map { |event| event_body(event) },
            truncated: events.limit(LIST_LIMIT + 1).count > LIST_LIMIT
          }
        end

        private

        def event_body(event)
          {
            id: event.id, actor_user_id: event.actor_user_id, actor_type: event.actor_type, action: event.action,
            resource_type: event.resource_type, resource_id: event.resource_id,
            organization_id: event.organization_id, branch_id: event.branch_id, metadata: event.metadata,
            occurred_at: event.occurred_at
          }
        end
      end
    end
  end
end
