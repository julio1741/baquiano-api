# NOTE: references the Webhooks domain services as ::Webhooks::*
# throughout — bare `Webhooks` inside this Api::V1::Webhooks::* controller
# resolves to this very routing namespace module instead of the top-level
# `Webhooks` domain module, same trap documented for Merchant/Customer/
# Courier in docs/architecture/domains.md (here it fails with
# "uninitialized constant" rather than a wrong-module NoMethodError, since
# there's no Api::V1::Webhooks::Receive to accidentally match).
module Api
  module V1
    module Webhooks
      # Unauthenticated by design — these come from external providers,
      # not our own app users. No real provider is wired up yet (section
      # 16); this only receives, verifies, and stores idempotently.
      class EventsController < Api::V1::BaseController
        def create
          raw_body = request.raw_post
          event = ::Webhooks::Receive.call(
            provider: params[:provider], provider_event_id: provider_event_id, event_type: parsed_body["type"],
            raw_body: raw_body, signature: request.headers["X-Webhook-Signature"]
          )
          ::Webhooks::ProcessJob.perform_later(event.id)
          render json: { received: true, id: event.id }, status: :ok
        end

        private

        def provider_event_id
          parsed_body["id"] || parsed_body["event_id"] || SecureRandom.uuid
        end

        def parsed_body
          @parsed_body ||= JSON.parse(request.raw_post)
        rescue JSON::ParserError
          @parsed_body = {}
        end
      end
    end
  end
end
