# Bearer access-token authentication shared by every authenticated
# namespace (customer/courier/merchant/admin). Access tokens are short-lived
# signed messages (Identity::IssueSession); the underlying session can still
# be revoked at any time, so every request re-checks it and the account.
module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate!
  end

  private

  def authenticate!
    payload = Identity::IssueSession.decode_access_token(bearer_token)
    raise UnauthorizedError.new("missing or invalid access token") if bearer_token.blank? || payload.nil?

    session = Session.find_by(id: payload["session_id"])
    raise UnauthorizedError.new("session no longer valid", code: "session_invalid") if session.nil? || !session.active?

    user = session.user
    raise ForbiddenError.new("account disabled", code: "account_disabled") if user.disabled_at.present?
    raise ForbiddenError.new("account locked", code: "account_locked") if user.locked_at.present?

    session.update_column(:last_used_at, Time.current)

    @current_session = session
    @current_user = user
    @current_device = session.device
    Current.actor_user_id = user.id
    Current.actor_type = session.device.app_type
  end

  def bearer_token
    header = request.headers["Authorization"]
    header&.start_with?("Bearer ") ? header.delete_prefix("Bearer ").strip : nil
  end

  def current_user
    @current_user
  end

  def current_session
    @current_session
  end

  def current_device
    @current_device
  end
end
