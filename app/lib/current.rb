class Current < ActiveSupport::CurrentAttributes
  attribute :request_id, :correlation_id
  attribute :actor_user_id, :actor_type
end
