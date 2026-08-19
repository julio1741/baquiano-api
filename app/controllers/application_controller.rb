class ApplicationController < ActionController::API
  before_action :set_current_request_details

  # rescue_from matches the most recently registered handler first, so the
  # generic StandardError catch-all must come before the specific ones.
  rescue_from StandardError, with: :render_internal_error
  rescue_from ApplicationError, with: :render_application_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def render_internal_error(error)
    raise error if Rails.env.local?

    Rails.logger.error(
      event: "unhandled_exception",
      exception_class: error.class.name,
      message: error.message,
      request_id: Current.request_id,
      correlation_id: Current.correlation_id
    )
    render json: error_body("internal_error", "Something went wrong"), status: :internal_server_error
  end

  def set_current_request_details
    Current.request_id = request.request_id
    Current.correlation_id = request.headers["X-Correlation-ID"].presence || SecureRandom.uuid
    response.set_header("X-Correlation-Id", Current.correlation_id)
  end

  def render_application_error(error)
    render json: error_body(error.code, error.message, error.details), status: error.status
  end

  def render_not_found(error)
    render json: error_body("not_found", error.message), status: :not_found
  end

  def render_record_invalid(error)
    details = error.record.errors.to_hash
    render json: error_body("validation_failed", "Validation failed", details), status: :unprocessable_content
  end

  def render_bad_request(error)
    render json: error_body("bad_request", error.message), status: :bad_request
  end

  def error_body(code, message, details = {})
    {
      error: {
        code: code,
        message: message,
        details: details,
        request_id: Current.request_id,
        correlation_id: Current.correlation_id
      }
    }
  end
end
