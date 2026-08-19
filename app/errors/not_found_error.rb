class NotFoundError < ApplicationError
  def initialize(message = nil, code: "not_found", details: {})
    super(message, code: code, status: :not_found, details: details)
  end
end
