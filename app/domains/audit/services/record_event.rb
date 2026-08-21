module Audit
  # The one place responsible for section 4.18's "Nunca registrar" list —
  # every caller must have already stripped tokens, OTP codes, passwords,
  # CVV, PAN, full receipts/documents, and unnecessary PII out of
  # `change_details`/`metadata` before calling this. Reads actor/request
  # context from Current (already populated by Authenticatable) so callers
  # only need to describe what happened, not who's doing it.
  class RecordEvent
    def self.call(...) = new(...).call

    def initialize(action:, resource_type:, resource_id: nil, organization: nil, branch: nil, metadata: {},
                   change_details: {}, request: nil)
      @action = action
      @resource_type = resource_type
      @resource_id = resource_id
      @organization = organization
      @branch = branch
      @metadata = metadata
      @change_details = change_details
      @request = request
    end

    def call
      AuditEvent.create!(
        actor_user_id: Current.actor_user_id, actor_type: Current.actor_type || "system", action: @action,
        resource_type: @resource_type, resource_id: @resource_id, organization: @organization, branch: @branch,
        request_id: Current.request_id, correlation_id: Current.correlation_id, ip_address: @request&.remote_ip,
        user_agent: @request&.user_agent, change_details: @change_details, metadata: @metadata,
        occurred_at: Time.current
      )
    end
  end
end
