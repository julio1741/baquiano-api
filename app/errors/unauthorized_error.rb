class UnauthorizedError < ApplicationError
  def initialize(message = nil, code: "unauthenticated", details: {})
    super(message, code: code, status: :unauthorized, details: details)
  end
end
