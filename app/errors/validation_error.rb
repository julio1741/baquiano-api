class ValidationError < ApplicationError
  def initialize(message = nil, code: "validation_failed", details: {})
    super(message, code: code, status: :unprocessable_content, details: details)
  end
end
